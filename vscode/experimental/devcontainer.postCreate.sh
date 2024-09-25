#!/usr/bin/bash
# This script is ran within the dev container and does not make
# changes to the host machine. It is used to set up the dev container.
# after it has built.
#
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

# Work directory of the mounted workspace
work_dir="/workspaces/workplace"

# Tokens
git_token="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"
openai_token="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"

# AWS params
sso_aws_url="https://d-9067900a0a.awsapps.com/start#"
sso_aws_region="us-east-1"

aws_sandbox_account_id="020127659860"
aws_qa_account_id="020127659860"
aws_uat_account_id="020127659860"
aws_prod_account_id="159247424670"
aws_root_account_id="538234414982"

aws_region="us-east-2"

# Github params
github_public_user="aaron-christian-nttd"
github_public_email="aaron.christian@nttdata.com"


#################
# Configure ENV #
#################
container_user=$1
bash_rc="/home/${container_user}/.bashrc"
zsh_rc="/home/${container_user}/.zshrc"
export GITHUB_TOKEN=${git_token}

# Set your ENV vars
echo "Configuring ENV vars..."
echo 'export GITHUB_TOKEN='${git_token} | tee -a ${bash_rc} ${zsh_rc}
echo 'export GOPRIVATE="github.com/launchbynttdata"' | tee -a ${bash_rc} ${zsh_rc}
echo 'export PATH="'${work_dir}'/.localscripts:${PATH}"' | tee -a ${bash_rc} ${zsh_rc}

# shell aliases
echo "Configuring shell aliases..."
echo 'alias git_sync="git pull origin main"' | tee -a ${bash_rc} ${zsh_rc} # Alias to sync the repo with the main branch
echo 'alias git_boop="git reset --soft HEAD~1"' | tee -a ${bash_rc} ${zsh_rc} # Alias to undo the last local commit but keep the changes

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo 'export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="obraun"
ENABLE_CORRECTION="false"
HIST_STAMPS="%m/%d/%Y - %H:%M:%S"
source $ZSH/oh-my-zsh.sh
' | tee -a ${zsh_rc}

#################
# Configure aws #
#################

# Default profile is set to the Launch Sandbox Account.
echo "Configuring .aws/config..."
mkdir -p ~/.aws
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
" > /home/${container_user}/.aws/config

#################
# Install Tools #
#################

# Install repo
mkdir -p /home/${container_user}/.bin
echo 'export PATH="${HOME}/.bin/repo:${PATH}"' | tee -a ${bash_rc} ${zsh_rc}
git clone https://github.com/launchbynttdata/git-repo.git /home/${container_user}/.bin/repo
chmod a+rx /home/${container_user}/.bin/repo

# Install asdf
echo "Installing asdf tool..."
git clone https://github.com/asdf-vm/asdf.git /home/${container_user}/.asdf --branch v0.14.0
echo '. "$HOME/.asdf/asdf.sh"' | tee -a ${bash_rc} ${zsh_rc}

# Install aws-sso-util as a make check dependency
python -m pip install aws-sso-util

# Install Launch CLI as a dev dependency
python -m pip install launch-cli
python -m pip install ruamel_yaml

## Uncomment the following lines if wish to have a local 
## dev source as the install folder
# cd ${work_dir}/launch-cli
# python -m pip install -e '.[dev]'
# python3.12 -m pip install boto3
# cd ${work_dir}container_user

#################
# Configure git #
#################

# Set up netrc
echo "Setting ~/.netrc variables..."
echo machine github.com >> ~/.netrc
echo login ${github_public_user} >> ~/.netrc
echo password ${git_token} >> ~/.netrc
chmod 600 /home/${container_user}/.netrc

# Configure git
echo "Configuring git..."
echo "[user]
        name = ${github_public_user}
        email = ${github_public_email}
[credential]
        credentialStore = cache
[push]
        autoSetupRemote = true
[safe]
        directory = *
" >> /home/${container_user}/.gitconfig

####################
# Install AI Tools #
####################

# installs nvm (Node Version Manager)
echo "Installing NodeJS..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
echo 'export NVM_DIR="$HOME/.nvm"' | tee -a ${bash_rc} ${zsh_rc}
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' | tee -a ${bash_rc} ${zsh_rc}
export NVM_DIR="/home/${container_user}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 20

# Install AI Shell
echo "Installing AI Shell..."
npm install -g @builder.io/ai-shell
echo "OPENAI_KEY=${openai_token}
SILENT_MODE=true
" > /home/${container_user}/.ai-shell

# Dev install of Termax
echo "Installing Termax..."
cd ${work_dir}/termax
python -m pip install -e '.[dev]'
cd ~

echo '[openai]
model = gpt-4o
temperature = 0.7
max_tokens = 1500
top_p = 1.0
top_k = 32
stop_sequences = None
candidate_count = 1
api_key = {openai_token}
host_url = None
base_url = 

[general]
platform = openai
auto_execute = True
show_command = False
storage_size = 2000' > /home/${container_user}/.termax/config
sed -i "s/{openai_token}/${openai_token}/g" /home/${container_user}/.termax/config

# Github Copilot CLI
echo "Installing Github Copilot CLI..."
gh auth login | echo -e "\n"
gh extension install github/gh-copilot
echo 'eval "$(gh copilot alias -- bash)"' | tee -a ${bash_rc} ${zsh_rc}

# Outlines
pip install outlines
pip install openai
pip install transformers datasets accelerate torch
pip install llama-cpp-python
pip install exllamav2 transformers torch
pip install mamba_ssm transformers torch
pip install vllm

###########
# Cleanup #
###########

# Set folder permissions
chown -R ${container_user}:${container_user} /home/${container_user}
chown -R ${container_user}:${container_user} ${work_dir}

echo "Dev container setup complete"