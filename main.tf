terraform {
  backend "s3" {
    bucket          = "cotb.terraform"
    key             = "latin-notes/terraform.tfstate"
    dynamodb_table  = "aws_cotb_dev_terraform_state"
    region          = "us-west-2"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.19.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "cotb_latin" {
  bucket = "cotb.latin"
}

resource "aws_s3_bucket_acl" "cotb_latin_acl" {
  bucket = aws_s3_bucket.cotb_latin.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "cotb_latin_policy" {
  bucket = aws_s3_bucket.cotb_latin.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
        {
            "Sid"       = "S3AllowPublicGetObject",
            "Effect"    = "Allow",
            "Principal" = "*",
            "Action"    = "s3:GetObject",
            "Resource"  = "arn:aws:s3:::cotb.latin/*"
        }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "cotb_latin_www" {
  bucket = aws_s3_bucket.cotb_latin.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "cotb_latin_index" {
  bucket = aws_s3_bucket.cotb_latin.id
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("index.html")
}

resource "aws_s3_object" "cotb_latin_conjugation_table" {
  bucket = aws_s3_bucket.cotb_latin.id
  key    = "essential-verbs.html"
  source = "essential-verbs.html"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("essential-verbs.html")
}

data "aws_route53_zone" "cotb_dev_zone" {
  name         = "cotb.dev."
  private_zone = false
}

resource "aws_route53_record" "cotb_latin_www" {
  zone_id = data.aws_route53_zone.cotb_dev_zone.zone_id
  name    = "latin.cotb.dev"
  type    = "A"
  
  alias {
    name    = aws_s3_bucket_website_configuration.cotb_latin_www.website_domain
    zone_id = aws_s3_bucket.cotb_latin.hosted_zone_id
    evaluate_target_health = false
  }
}

output "website" {
  value = aws_s3_bucket_website_configuration.cotb_latin_www.website_endpoint
}

