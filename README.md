# Quarterly Salary Report Generator
## This script will take the SQL dumps provided in the `test_db` directory and output a report containing the quarterly average salary expenditure of each department for the year provided.

### usage
```bash
git clone https://github.com/datacharmer/test_db test_db
./qsalary.sh <year> <run_option>
```

### available run options
`print` - This will create the report and print it to the console
`serve` - This will create the report and serve it as plain text on port 80 for web browser access
`test` - This will create the report then validate the data comparing the data

## Additional ways to run the application

### Run in Docker
```bash
docker build -t "qsalary:latest" .
docker run qsalary:latest <year> <run_option>
```

#### Run with docker-compose
```bash
sed -i.bak 's/QYEAR/<year>/g' docker-compose.yml
docker-compose up
```

### Run in AWS

[Please look here for instructions on how to accomplish this](/terraform/)

** This report is not 100% accurate as it does not take fiscal year into account, and provides an average of all salaries for the year paid out by that department. **
