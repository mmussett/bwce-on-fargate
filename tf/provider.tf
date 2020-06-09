
provider "aws" {
  region = var.region
  shared_credentials_file = var.shared_credential_file
  profile = var.profile
}



/*
provider "aws" {
    region = var.region
    access_key = var.access_key
    secret_key = var.secret_key
}
*/