#!/usr/bin/env bash

echo "Do you want to generate a new ssh key? [y/N] "
read new_key

function send_to_github {
	echo "What is your github username?"
	read username

	echo "What public key file do you want to use? Default: ~/.ssh/id_rsa.pub "
	read ans
	if [ ! -z $ans ] && [ -f $ans ]
	then
		file=$ans
	else
		file=~/.ssh/id_rsa.pub
	fi

	echo "What should the key be called in the Github UI? "
	read title

	echo "Username: $username"
	echo "File: $file"
	echo "Title: $title"
	
	# Send the key
	key=$(cat $file)
	echo $key
	curl -u "$username" --data '{"title":"$title","key":"$key"}' https://api.github.com/user/keys
	#curl --data '{"title":"$title","key":"$key"}' https://api.github.com/user/keys
}

case $new_key in
	y)
		echo "What is your email address?"
		read email
		ssh-keygen -t rsa -b 4096 -C "$email"

		send_to_github
		;;
	*)
		send_to_github
		;;
esac
