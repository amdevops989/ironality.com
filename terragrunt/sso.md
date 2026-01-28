aws organization : ironcore
sso user : seniordevops-am || mdp add @before numbers
https://ironcoredigitalportal.awsapps.com/start
sudo apt install awscli -y
aws configure sso
profile dev-sso + prod-sso
aws configure list-profiles
aws sso login --profile dev-sso
# Add the export to your Zsh config
echo 'export AWS_PROFILE=dev-sso' >> ~/.zshrc

# Reload the Zsh config
source ~/.zshrc
echo $AWS_PROFILE
