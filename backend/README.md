# Backend
## Description
...

## Requirements
- Linux
- Java 23
- Redgate Flyway 11.1.0
- MySQL 9.1.0
- Apache Maven 3.9.9
- Docker 27.4.1 (only for development)

## Deploying
- Configure the `src/main/resources/application.properties` file.

> Warning: `flyway directory/drivers` directory must contain the `mysql-connector-j-9.1.0` jar file.  

- Run the migrations:
```bash
# Change the `-url` parameter 
flyway -url=jdbc:mysql://root:rootpw@localhost:3306/air_chain_app_db -locations=filesystem:./migrations migrate
```

- Run the app:
```bash
mvn spring-boot:run
```

## Running locally
> Warning: There is a Postman collection called `airchainapp.postman_collection`. You can use it to make requests.

- Start the containers running the command:
```bash
docker compose -f docker-compose-dev.yaml up
```

- Follow the [deploying](#deploying) section.  