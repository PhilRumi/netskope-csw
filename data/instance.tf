############################################################
### Student Instances
############################################################
resource "aws_instance" "student_instance" {
    count = var.student_instance_count
    ami = var.student_instance_ami
    instance_type = var.student_instance_type
    subnet_id = "${aws_subnet.subnet1.id}"
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.student_security_group.id}"]
    tags = {
      Name = "${local.workspace["name"]}-${var.student_prefix}-${format("%02d", count.index)}"
    } 
}

resource "aws_eip" "student_eip" {
  count = var.student_instance_count
  instance = aws_instance.student_instance[count.index].id
  vpc      = true
}

############################################################
### Publisher Instance
############################################################
resource "aws_instance" "publisher_instance" {
    count = var.csw_publisher ? 1 : 0
    ami = var.publisher_instance_ami
    instance_type = var.publisher_instance_type
    subnet_id = "${aws_subnet.subnet2.id}"
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.publisher_security_group.id}"]
    tags = {
      Name = "${local.workspace["name"]}-CSW_Publisher"
    }
    # user_data     = length(var.token) == 0 ? null : data.template_cloudinit_config.userdata.rendered #####userdata als txt bedingung an variable
}

resource "aws_eip" "publisher_eip" {
  count = var.csw_publisher ? 1 : 0
  instance = aws_instance.publisher_instance[0].id
  vpc      = true
}

############################################################
### Webserver Instance
############################################################
resource "aws_instance" "webserver_instance" {
    ami = var.webserver_instance_ami
    instance_type = var.webserver_instance_type
    subnet_id = "${aws_subnet.subnet1.id}"
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.webserver_security_group.id}"]
    tags = {
      Name = "${local.workspace["name"]}-CSW_Webserver"
    } 

  }
    

############################################################
### Guacamole Instance
############################################################
resource "aws_instance" "guacamole_instance" {
    ami = var.guacamole_instance_ami
    instance_type = var.guacamole_instance_type
    subnet_id = "${aws_subnet.subnet1.id}"
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.guacamole_security_group.id}"]
    tags = {
      Name = "${local.workspace["name"]}-CSW_Guacamole"
    } 
}
    resource "null_resource" "configure-guacamole" {
   connection {
   type = "ssh"
   host = aws_eip.guacamole_instance_eip.public_ip
   user = "centos"
   private_key = file("./labkey.pem")
 }

 provisioner "remote-exec" {
   inline = [
     "sudo echo \"export env=${local.workspace["namespace"]}\" >> ~/.bashrc",
     "source ~/.bashrc",
     "cd /home/centos/docker_umgebung/guacamole_version1/",
     "docker-compose up -d",
     "exit"
     ]
   }  
 }

 resource "aws_eip" "guacamole_instance_eip" {
  instance = aws_instance.guacamole_instance.id
  vpc      = true
}

############################################################
### Master Instance
############################################################

resource "aws_instance" "master_instance" {
    ami = var.master_instance_ami
    instance_type = var.master_instance_type
    subnet_id = "${aws_subnet.subnet1.id}"
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.master_security_group.id}"]
    tags = {
      Name = "${local.workspace["name"]}-CSW_Master"
    }
}

resource "aws_eip" "master_instance_eip" {
  instance = aws_instance.master_instance.id
  vpc      = true
}



############################################################
### New Ubuntu Publisher with Token Data -> SEE user_data.yaml
############################################################

resource "aws_instance" "ubuntu_publisher_instance" {
    count = var.ubuntu_publisher ? 1 : 0
    ami = var.ubuntu_publisher_instance_ami
    instance_type = var.ubuntu_publisher_instance_type
    subnet_id = "${aws_subnet.subnet2.id}"
    key_name = var.key_name
    user_data = length(var.token) == 0 ? null : data.template_file.userdata.rendered
    vpc_security_group_ids = ["${aws_security_group.publisher_security_group.id}"]
    tags = {
      Name = "${local.workspace["name"]}-CSW_Ubuntu_Publisher"
    }
}

resource "aws_eip" "ubuntu_publisher_eip" {
  count = var.ubuntu_publisher ? 1 : 0
  instance = aws_instance.ubuntu_publisher_instance[0].id
  vpc      = true
}

data template_file "userdata" {
  template = file("user_data.yaml")

  vars = {
    token       = var.token
  }
}




