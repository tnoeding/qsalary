FROM centos

ADD qsalary.sh /usr/local/bin/qsalary.sh

WORKDIR /opt/qsalary

RUN apk add --no-cache git netcat-openbsd \
    && git clone https://github.com/datacharmer/test_db /opt/qsalary/test_sb \
    && chmod +x /usr/local/bin/qsalary.sh \

CMD ["qsalary.sh"]
