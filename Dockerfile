FROM tomcat:9

RUN chmod -R 777 /usr/local/tomcat/webapps

COPY target/demo.war /user/local/tomcat/webapps

EXPOSE 8080

ENTRYPOINT ["sh", "/user/local/tomcat/bin/startup.sh"]
