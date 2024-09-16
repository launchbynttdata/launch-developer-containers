#!/usr/bin/bash
# This script is ran within the dev container and does not make
# changes to the host machine. It is used to set up the dev container.
#
# @param container_user: The user that the dev container is running as
# @param work_dir: The vscode workspace open in the dev container
# @param git_token: The GitHub token used to authenticate with GitHub
# @param sso_aws_url: The URL for the AWS SSO login page
# @param sso_aws_region: The region that the AWS SSO login page is hosted in
# @param aws_root_account_id: The AWS account ID for the root account
# @param aws_prod_account_id: The AWS account ID for the production account
# @param aws_sandbox_account_id: The AWS account ID for the sandbox account
# @param aws_region: The region that the AWS CLI should use
# @param github_public_user: The GitHub username to use for public repositories
# @param github_public_email: The email address to use for public repositories

work_dir="/workspaces/CHANGEME"
git_token="CHANGEME"

sso_aws_url="CHANGEME"
sso_aws_region="us-east-1"

aws_root_account_id="CHANGEME"
aws_prod_account_id="CHANGEME"
aws_sandbox_account_id="CHANGEME"
aws_region="us-east-2"

github_public_user="CHANGEME"
github_public_email="CHANGEME@CHANGEME.com"

# Set your ENV vars
echo 'export GITHUB_TOKEN='${git_token} >> /home/${container_user}/.bashrc
echo 'export GOPRIVATE="github.com/launchbynttdata"' >> /home/${container_user}/.bashrc

# Local user scripts to added to PATH for execution
echo 'export PATH="'${work_dir}'/.localscripts:${PATH}"' >> /home/${container_user}/.bashrc

# Install repo
mkdir -p /home/${container_user}/.bin
echo 'export PATH="${HOME}/.bin/repo:${PATH}"' >> /home/${container_user}/.bashrc
git clone https://github.com/launchbynttdata/git-repo.git /home/${container_user}/.bin/repo
chmod a+rx /home/${container_user}/.bin/repo

# Install asdf
git clone https://github.com/asdf-vm/asdf.git /home/${container_user}/.asdf --branch v0.14.0
echo '. "$HOME/.asdf/asdf.sh"' >> /home/${container_user}/.bashrc

# Install dependencies
python -m pip install aws-sso-util
python -m pip install ruamel_yaml

# Install Launch CLI as a dev dependency
python -m pip install launch-cli

## Uncomment the following lines if wish to have a local 
## dev source as the install folder
# cd ${work_dir}/launch-cli
# python -m pip install -e '.[dev]'
# python3.12 -m pip install boto3
# cd ${work_dir}

# Set up netrc
echo "Setting /home/${container_user}/.netrc variables"
echo machine github.com >> /home/${container_user}/.netrc
echo login ${github_public_user} >> /home/${container_user}/.netrc
echo password ${git_token} >> /home/${container_user}/.netrc
chmod 600 /home/${container_user}/.netrc

# Configure git
echo "
[user]
        name = ${github_public_user}
        email = ${github_public_email}
[push]
        autoSetupRemote = true
[safe]
        directory = *
" >> /home/${container_user}/.gitconfig

# shell aliases
echo 'alias git_sync="git pull origin main"' >> /home/${container_user}/.bashrc # Alias to sync the repo with the main branch
echo 'alias git_boop="git reset --soft HEAD~1"' >> /home/${container_user}/.bashrc # Alias to undo the last local commit but keep the changes

# Set up AWS Config
# Default profile is set to the Sandbox Account.
mkdir -p /home/${container_user}/.aws
echo "[default]
region = ${aws_region}
output = json
sso_start_url = ${sso_aws_url}
sso_region = ${sso_aws_region}
sso_account_name = Launch Sandbox Account
sso_account_id = ${aws_sandbox_account_id}
sso_role_name = AdministratorAccess
credential_process = aws-sso-util credential-process --profile launch-sandbox-admin
sso_auto_populated = true

[profile launch-prod-admin]
sso_start_url = ${sso_aws_url}
sso_region = ${sso_aws_region}
sso_account_name = Launch Production
sso_account_id = ${aws_prod_account_id}
sso_role_name = AdministratorAccess
region = ${aws_region}
credential_process = aws-sso-util credential-process --profile launch-prod-admin
sso_auto_populated = true

[profile launch-root-admin]
sso_start_url = ${sso_aws_url}
sso_region = ${sso_aws_region}
sso_account_name = Launch Root Account
sso_account_id = ${aws_root_account_id}
sso_role_name = AdministratorAccess
region = ${aws_region}
credential_process = aws-sso-util credential-process --profile launch-root-admin
sso_auto_populated = true

[profile launch-sandbox-admin]
sso_start_url = ${sso_aws_url}
sso_region = ${sso_aws_region}
sso_account_name = Launch Sandbox Account
sso_account_id = ${aws_sandbox_account_id}
sso_role_name = AdministratorAccess
region = ${aws_region}
credential_process = aws-sso-util credential-process --profile launch-sandbox-admin
sso_auto_populated = true
" >> /home/${container_user}/.aws/config

# Set folder permissions
chown -R ${container_user}:${container_user} /home/${container_user}
chown -R ${container_user}:${container_user} ${work_dir}

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=\"obraun\"
ENABLE_CORRECTION=\"false\"
HIST_STAMPS=\"%m/%d/%Y - %H:%M:%S\"
plugins=(git)
source \$ZSH/oh-my-zsh.sh
. /opt/homebrew/opt/asdf/libexec/asdf.sh
export JAVA_HOME=\"/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home\"
export PATH=\"\$JAVA_HOME/bin:\$PATH\"
export JAVA_HOME=\$(/usr/libexec/java_home)
" > /home/${container_user}/.zshrc
sudo chsh -s $(which zsh) $USER

echo "Dev container setup complete"