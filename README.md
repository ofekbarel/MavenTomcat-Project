# Welcome to my Maven-Tomcat Project ! 🐱
**introduction** :
In this project we created a simple application using maven.
First, with the help of terraform, we will set up a machine in Azure which will be used by us for the entire CI CD process.
After that we will use jenkins for CI to build the maven application, and create a .war file for us.
After that, he will package the application using docker that will be built according to the dockerfile based on tomcat:9, and push it to ACR in Azure.
After that we will reach the CD part, this process will also run with jenkins.
We will change the image tag for our webbapp that runs in Azure, and thus we can assign the tags according to the latest image in ACR

![Image alt text](images/diagram.png)


---


## stpes : 🔨
### Terraform - set up a virtual machine in Azure :

At this stage we will first set up a virtual machine in azure, of course we will also need vnet, subnet, nsg, public ip and more..
Inside the main.tf file we define all these components, including opening port 22 and 8080 in order to allow jenkins to run, and for us to connect to the machine.
The machine will receive a password according to terraform.tfvars which is in .gitignore and contains sensitive information.
Finally, you we do the following commands:

**terraform init**

**terraform plan -out=tfplan**

**terraform apply tfplan**


