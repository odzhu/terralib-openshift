module "provisioner" {
  source            = "../asg"
  subnet_ids        = "${var.subnet_ids}"
  environment       = "${var.environment}"
  name              = "${var.provisioner_name}"
  vpc_id            = "${var.vpc_id}"
  instance_type     = "${var.provisioner_instance_type}"
  instance_profile  = "${aws_iam_instance_profile.provisioner.name}"
  ami               = "${var.provisioner_ami}"
  instance_key_name = "${var.instance_key_name}"
  load_balancers    = ["${aws_elb.master.name}"]
  user_data         = "${data.template_file.provisioner.rendered}"
  management_net    = "${var.management_net}"
  security_groups   = ["${aws_security_group.default.id}"]
}

data "template_file" "provisioner" {
  template = "${file("${var.provisioner_user_data}")}"

  vars {
    master        = "${replace("${module.master.name}", "-", "_")}"
    environment   = "${var.environment}"
    public_domain = "${var.public_domain}"
    region        = "${data.aws_region.current.name}"
    log_group     = "${aws_cloudwatch_log_group.openshift.name}"
  }
}

data "aws_region" "current" {
  current = true
}

resource "aws_ssm_document" "openshift" {
  name = "${var.environment}_openshift"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "2.0",
    "description": "Run cluster provision",
    "parameters": {

    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": ["bash -c 'EC2_INI_PATH=/tmp/inventory/ec2.ini ansible-playbook -i /tmp/inventory /openshift-ansible/playbooks/byo/config.yml'"]
          }
        ]
      }
    }
  }
DOC
}
