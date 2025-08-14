#clean the exist projects
oc delete all -l app=mysql
oc delete all -l app=fastapi-app

#create the secret
oc create secret generic mysql-secret \
  --from-literal=MYSQL_ROOT_PASSWORD=your_root_password \
  --from-literal=MYSQL_USER=myuser \
  --from-literal=MYSQL_PASSWORD=mypassword \
  --from-literal=MYSQL_DATABASE=mydb

#create the MySQL database
oc new-app mysql:8 \
  --name=mysql \
  -e MYSQL_ROOT_PASSWORD=your_root_password \
  -e MYSQL_USER=myuser \
  -e MYSQL_PASSWORD=mypassword \
  -e MYSQL_DATABASE=mydb

#get the mysql pod name
MYSQL_POD=$(oc get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}')

#copy the data to the mysql pod
oc cp scripts/create_data.sql $MYSQL_POD:/tmp/create_data.sql
oc cp scripts/insert_data.sql $MYSQL_POD:/tmp/insert_data.sql

#run the sql scripts inside the mysql pod
oc rsh $MYSQL_POD
mysql -u root -p"$MYSQL_ROOT_PASSWORD" mydb < /tmp/create_data.sql
mysql -u root -p"$MYSQL_ROOT_PASSWORD" mydb < /tmp/insert_data.sql


# build the FastAPI application in binary
oc new-app --name=fastapi-app --strategy=docker --binary
oc start-build fastapi-app --from-dir=. --follow

#connect the FastAPI application to the MySQL database using the secret
oc set env deployment/fastapi-app --from=secret/mysql-secret
oc set env deployment/fastapi-app MYSQL_HOST=mysql MYSQL_PORT=3306

# get the FastAPI pod name
FASTAPI_POD=$(oc get pod -l app=fastapi-app -o jsonpath='{.items[0].metadata.name}')

# expose the FastAPI application in port 8000
oc expose pod $FASTAPI_POD --name=fastapi-app --port=8000 --target-port=8000


# create the route in order to access the FastAPI application from outside
oc expose svc/fastapi-app
oc get route fastapi-app


