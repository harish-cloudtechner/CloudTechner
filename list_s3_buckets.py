#date=`TZ=IST-5:30 date +%F_%T`
import boto3
s3_ob=boto3.resource('s3') 
for i in s3_ob.buckets.all():
 print i.name

buck = input("enter the option (0/1)")
if buck == 0:
    string = input("Enter the bucket name: ")
    file_name = str(input("Enter the file name which you want to delete"))
    response = s3.delete_bucket(Bucket=file_name)
    response = client.delete_bucket(
    Bucket='string',)
s3_ob.delete_object(Bucket = 'buck', Key = 'file_name')
else:
    print "continue the code"
             
session=boto3.Session(profile_name="default")
ec2=session.resource(service_name="ec2")
for j in ec2.instances.all():
 print (j.id, j.state['Name'])
ids = input("Enter the instance id: ")
ec2 = boto3.resource('ec2')
print "0 for stop,1 for start,2 for terminate" 
choices = input("Enter the option : (0/1/2)")
if choices == 0:
  ec2.instances.filter(InstanceIds = [ids]).stop()
elif choices == 1:
  ec2.instances.filter(InstanceIds = [ids]).start()
elif choices == 2:
  ec2.instances.filter(InstanceIds = [ids]).terminate()
else:
 print "invalid choice"
 
print "All the available db instances"
session=boto3.Session(profile_name="default",region_name='ap-south-1')
rds=session.client(service_name="rds")
 
dbs = rds.describe_db_instances()
for db in dbs['DBInstances']:
  print("%s@%s:%s %s") % (db['MasterUsername'],db['Endpoint']['Address'],db['Endpoint']['Port'],db['DBInstanceStatus'])
  print "stop database instance"
response = rds.stop_db_instance( DBInstanceIdentifier='dbinst', DBSnapshotIdentifier='string' )
#response = rds.delete_db_instance(
#  DBInstanceIdentifier = 'dbinst',
#  SkipFinalSnapshot = true
#  )
print(response)      

