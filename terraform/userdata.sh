#!/bin/bash
# tsn userdata for host

# Update system
yum update -y
logger -p user.notice "BOOTSTRAP: Updating system - $?"

# Installing Docker
yum install -y docker git
logger -p user.notice "BOOTSTRAP: Installing Docker - $?"

# Installing Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
logger -p user.notice "BOOTSTRAP: Installing Docker Compose - $?"

# Starting Docker
/etc/init.d/docker start
logger -p user.notice "BOOTSTRAP: Starting Docker Daemon - $?"

# Making the work directory
mkdir -p /opt/qsalary

# Writing qsalary.sh
cat > /opt/qsalary/qsalary.sh <<EOF
#!/usr/bin/env bash
# Department Salary Quarterly Report
# tsn CoT
# usage: ./qsalary.sh <year>
# example: ./qsalary.sh 2000

# Create Variables and Temp Location
REPORT_YEAR=${1?Year is missing, please pass a year to the command.\ Example: ./qsalary.sh 2000}
TMPDIR=$(mktemp -d /tmp/qsalary-XXXX)
DEPT=$(mktemp -p $TMPDIR -t dept-XXXX)

# Help output if requested
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: `basename $0` <year> <run option>"
  echo "Example: `basename $0` 2000 print"
  echo " Run Options: print serve test"
  exit 0
fi

# Create a trap for cleaning up if we have issues
cleanup() {
  rm $DEPT
  rm -rf $TMPDIR
}
trap cleanup 0


# Get Departments
getDepartment() {
echo "Getting Departments"
grep -o '(.*' test_db/load_departments.dump | cut -f1 -d, | sed "s/[(']//g" >> $DEPT
}

# Loop through departments, create temp files for each department, get employee IDs for departments
employeeID() {
echo "Getting Employee IDs"
for i in `cat $DEPT`; do 
grep -h -o '(.*' test_db/load_dept_emp.dump test_db/load_dept_manager.dump | grep -w $i | cut -f1 -d, | cut -c2- | sort >> $TMPDIR/$i;
done
}

# Get Requested Year Data
getYear() {
echo "Getting requested year data"
awk -F"," '$3~/^'\'''$REPORT_YEAR'/' test_db/load_salaries*.dump | sed "s/[(']//g" | sort >> $TMPDIR/$REPORT_YEAR-data
}

# Get Salary By Year
getSalary() {
echo "Getting Salaries"
for i in `cat $DEPT`; do 
awk -F"," 'FNR == NR {arr[$0] = 1; next} ($1 in arr)' $TMPDIR/$i $TMPDIR/$REPORT_YEAR-data | cut -f2 -d, >> $TMPDIR/$i-total
done
}

# Generate the Report
createReport() {
echo "Creating Quarterly Salary Report"
echo "$REPORT_YEAR Quarterly Salary Report" >> $TMPDIR/report.txt
echo "" >> $TMPDIR/report.txt
for i in `cat $DEPT`; do
grep $i test_db/load_departments.dump | cut -f2 -d, | sed "s/[();']//g" >> $TMPDIR/report.txt;
awk '{ total+=$1 } END{  print int(total/4) }' $TMPDIR/$i-total >> $TMPDIR/report.txt;
echo "" >> $TMPDIR/report.txt
done
}

# Verify the numbers
verifyReport() {
echo "Verifying Totals"
awk -F"," '$3~/^'\'''$REPORT_YEAR'/' test_db/load_salaries1.dump test_db/load_salaries2.dump test_db/load_salaries3.dump | cut -f2 -d, >> $TMPDIR/verify_report
for i in `cat $DEPT`; do
paste -sd+ $TMPDIR/$i-total | bc >> $TMPDIR/report_numbers;
# Check to see if the department has more salaries then employees
if [[ $(echo "`wc -l $TMPDIR/$i | cut -f1 -d" "` >= `wc -l $TMPDIR/$i-total | cut -f1 -d" "`" | bc) = 0 ]];
then
echo "ERROR - The department $i has more salaries than possible."
exit 1
fi
done
# Check whether the total salaries for the year match the total for all departments
paste -sd+ $TMPDIR/report_numbers | bc >> $TMPDIR/report_total
paste -sd+ $TMPDIR/verify_report | bc >> $TMPDIR/verify_total
diff -qy $TMPDIR/report_total $TMPDIR/verify_total
if [ $? -eq 0 ]
then
  echo "The values add up, the report is good"
  exit 0
else
  echo "ERROR - The values are different, something is wrong" >&2
  exit 1
fi
}

# Print out the report
printReport() {
cat $TMPDIR/report.txt
}

# Provide the report for web clients
serveReport() {
echo "Starting Basic Web Server"
echo "Listening on port 8080"
while :; do nc -l 8080 < $TMPDIR/report.txt; done
}

case $2 in
print)
echo "Printing Report to Console"
# Work
getDepartment
employeeID
getYear
getSalary
createReport
printReport
;;
serve)
echo "Serving the report for browser access"
# Work
getDepartment
employeeID
getYear
getSalary
createReport
serveReport
;;
test)
echo "Running Tests to verify data"
# Work
getDepartment
employeeID
getYear
getSalary
createReport
verifyReport
printReport
;;
*)
echo "Run option not passed, printing and serving to browser"
# Work
getDepartment
employeeID
getYear
getSalary
createReport
verifyReport
printReport
serveReport
;;
esac

# disable the trap
trap '' 0

# run cleanup
cleanup
EOF

# Writing docker-compose.yml and Dockerfile
cat > /opt/qsalary/Dockerfile <<EOF

FROM centos

ADD qsalary.sh /usr/local/bin/qsalary.sh

WORKDIR /opt/qsalary

RUN apk add --no-cache git netcat-openbsd \
    && git clone https://github.com/datacharmer/test_db /opt/qsalary/test_sb \
    && chmod +x /usr/local/bin/qsalary.sh \

CMD ["qsalary.sh"]
EOF
cat > /tmp/qsalary/docker-compose.yml <<EOF
version: "3.4"

services:
	qsalary:
		build: .
		image: qsalary:latest
		command: "qsalary.sh YEAR serve"
EOF

logger -p user.notice "BOOTSTRAP: Writing docker-compose.yml - $?"

# Run application
sleep 60
cd /tmp/qsalary
screen -d -m /usr/local/bin/docker-compose --project-directory /opt/qsalary/ up
logger -p user.notice "BOOTSTRAP: Application Started - $?"
