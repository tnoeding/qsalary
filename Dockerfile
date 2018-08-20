FROM centos

ADD qsalary.sh /usr/local/bin/qsalary.sh

WORKDIR /opt/qsalary

RUN yum update -y \
    && yum install git nc \
    && git clone https://github.com/datacharmer/test_db /opt/qsalary/test_sb \
    && chmod +x /usr/local/bin/qsalary.sh \

CMD ["qsalary.sh"]
