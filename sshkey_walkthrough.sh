# GitHub installation script, for use in EECS 183, University of Michigan Ann Arbor
# Copyright Steve Merritt 12/20/2014

#!/bin/bash


echo "----------------------------------------------------"
echo "| EECS 183 SSH-Key Generator                       |"
echo "| Copyright Steve Merritt 12/20/2014               |"
echo "| Licensed for use by the University of Michigan   |"
echo "----------------------------------------------------"
echo

echo "Hi there, awesome person! Let's get you set up to use Git on your computer."; echo

#enter username
read -p "To get started, enter your uniqname: " uniqname; echo

echo "Hi, $uniqname!"; echo
sleep 1
#check installation of Git
read -p "First, let's make sure you have Git installed. (hit [ENTER] to continue)"
sleep 1
if [[ "$(git)" == *"usage: git"* ]]
then
    echo "I've found a working installation of Git on your computer, so we're good to go!"
else
    echo " -- No Working Git Installation Found -- "; echo
    echo "Looks like you haven't installed Git yet! Since you're running a [bash] shell, I'll assume
you're using OS X. Go ahead and type 'git' at the command line to begin installation of Git. When
it finishes, run this program again to continue."
    exit
fi
sleep 2

echo "--------------------------------------------------------------------------"
echo "-- Git Installation Complete ---------------------------------------------"
echo "--------------------------------------------------------------------------"
sleep 2
echo

echo "Next, we should make sure you have a GitHub account. 
If you don't, you'd better head over to https://github.com and register an account!"
read -p "Just hit the [ENTER] key when you're ready to continue."

echo "--------------------------------------------------------------------------"
echo "-- GitHub Account Creation Complete --------------------------------------"
echo "--------------------------------------------------------------------------"
echo; sleep 2

echo "Our final step is to ensure that GitHub can recognize your computer. We want to make
sure that only your computer can push code to your account! To do this, we'll create
an SSH key. This is basically a unique identity that your computer will use to encrypt
all of its communications with GitHub, so that all your data is secure."
echo; sleep 4

if [ -f ~/.ssh/id_rsa ]
then
    echo "I took a quick look at your SSH configuration files, and it looks like you have an SSH key on your computer that we can use!"
else
    # generate a new SSH key at ~/.ssh/id_rsa
    yes '' | ssh-keygen -t rsa -C "$uniqname@example.com"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    location=`pwd ~`
    echo "I went ahead and created a new SSH key for you, and saved it at '$location'"
fi
sleep 1

echo "--------------------------------------------------------------------------"
echo "-- SSH Key Generation Complete -------------------------------------------"
echo "--------------------------------------------------------------------------"
echo; sleep 2

echo
echo "Now we need to link this 'SSH-key' identifier to your GitHub account, so GitHub knows that this identity means \"$uniqname's computer\" - and to do that, I'll need your GitHub credentials."
echo; sleep 2

# get the login info for students
read -p "Enter your GitHub username: " uname
stty -echo
echo "Now I'll need your password - but since it's a password, I'll hide the characters you type."
read -p "Enter your GitHub password: " passw; echo
stty echo

# communicate with the GitHub server to ensure that accurate credentials were provided

echo "------------------------------------------------------------------------"
echo "-- Communicating With Server -------------------------------------------"
finalres=`curl -u "$uname:$passw" 'https://api.github.com/user/keys'`
echo "------------------------------------------------------------------------"
echo; sleep 1
while [[ "$finalres" == *"Bad credentials"* ]]
do
    echo " -- GitHub Authorization Failed -- "
    echo
    echo "Looks like GitHub rejected the username and password that you provided."
    echo "Try entering them again:"
    echo
    read -p "Enter your GitHub username: " uname
    stty -echo
    read -p "Enter your GitHub password: " passw; echo
    stty echo
    echo "------------------------------------------------------------------------"
    echo "-- Communicating With Server -------------------------------------------"
    finalres=`curl -u "$uname:$passw" 'https://api.github.com/user/keys'`
    echo "------------------------------------------------------------------------"
    echo; sleep 1
done
echo
echo " -- GitHub Authorization Succeeded -- "
echo; sleep 1

echo "Cool - looks like those are the right credentials, and GitHub agrees. "
echo "Now, we'll upload the public key to the server."
echo; sleep 2

# now that communication has been established, upload the SSH public key
pubkey=`cat ~/.ssh/id_rsa.pub`
data="{\"title\": \"$uniqname's Computer\",\"key\": \"$pubkey\"}"
echo "------------------------------------------------------------------------"
echo "-- Communicating With Server -------------------------------------------"
res=`curl --user "$uname:$passw" --data "$data" https://api.github.com/user/keys`
echo "------------------------------------------------------------------------"
echo; sleep 1

if [[ "$res" == *"verified\": true"* ]]
then
    echo "-- Public Key successfully uploaded to https://github.com/$uname --"
    echo
elif [[ "$res" == *"message\": \"Validation Failed"* ]]
then
    if [[ "$res" == *"message\": \"key is already in use"* ]]
    then
        echo "Hmm. Looks like we didn't even need to do this step - your SSH key has already been validated on GitHub!"
    fi
else
    echo "Well, looks like something broke... Tell a GSI that I couldn't upload your public key to your GitHub account."
    exit
fi

echo "--------------------------------------------------------------------------"
echo "-- GitHub SSH Key Verification Complete ----------------------------------"
echo "--------------------------------------------------------------------------"

echo; sleep 1
echo "Cleaning up and running final checks..."
# assert that the user can connect to GitHub and authenticate
sleep 2
if [[ "$(ssh -T git@github.com 2>&1)" == *"Hi $uname! You've successfully authenticated, but GitHub does not provide shell access."* ]]
then
    echo "Congratulations! You're ready to use GitHub from your computer."
else
    echo "Looks like something might've gone slightly wrong during installation. Inform a GSI that
despite following all the directions, you can't connect to GitHub via SSH. They'll fix it!"
fi
exit
