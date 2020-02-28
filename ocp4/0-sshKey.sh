ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa    
eval "$(ssh-agent -s)"
ssh-add  ~/.ssh/id_rsa
