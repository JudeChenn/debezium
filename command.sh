https://medium.com/@elifsinem.aktas/capturing-mysql-database-changes-with-debezium-7b4eb45d9356
1. start docker
docker-compose -f docker-compose-mysql.yaml up -d

2. setting DB
docker-compose -f docker-compose-mysql.yaml exec mysql bash -c 'mysql -u root -pdebezium'
SELECT user,host FROM mysql.user;
CREATE DATABASE dataops;
GRANT ALL ON dataops.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE sinkdb;
GRANT ALL ON sinkdb.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
SHOW databases;

docker-compose -f docker-compose-mysql.yaml exec mysql bash -c 'mysql -u debezium -pdbz'
CREATE TABLE dataops.example(
    customerId int,
    customerFName varchar(255),
    customerLName varchar(255),
    customerCity varchar(255)
);
USE dataops;
SHOW tables;

3. register connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-source-connector.json
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-sink-connector.json
curl -i -X GET -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/
curl -X DELETE http://localhost:8083/connectors/mysql-sink-connector
docker logs debezium-connect-1 > dbz.log

4. check kafka topic and consume topic
docker-compose -f docker-compose-mysql.yaml exec kafka /kafka/bin/kafka-topics.sh \
    --bootstrap-server kafka:9092 \
    --list
docker-compose -f docker-compose-mysql.yaml exec kafka /kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server kafka:9092 \
    --from-beginning \
    --property print.key=true \
    --topic dbserver1.dataops.example

5. write to DB
INSERT INTO example VALUES (1,"Richard","Hernandez","Brownsville"),\
  (2,"Mary","Barrett","Littleton"),\
  (3,"Ann","Smith","Caguas"),\
  (4,"Mary","Jones","San Marcos"),\
  (5,"Robert","Hudson","Caguas");
UPDATE example SET customerCity = 'Ocean Drive' WHERE customerId = 1;
DELETE FROM example WHERE customerId = 1;

6. monitor the source & sink connector
consumer json msg -> https://jsoncrack.com/editor
USE sinkdb;
SHOW tables;
