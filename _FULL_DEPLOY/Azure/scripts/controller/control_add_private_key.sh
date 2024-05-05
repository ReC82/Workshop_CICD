$keyname="$2"
$keysecret="$1"

echo "$keysecret" > ~/.ssh/$keyname.pem
chmod 600 ~/.ssh/$keyname.pem