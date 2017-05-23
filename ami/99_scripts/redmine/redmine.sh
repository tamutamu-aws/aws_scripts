CURDIR=$(cd $(dirname $0) && pwd)

bash -l "$CURDIR/install_redmine.sh"
bash -l "$CURDIR/install_backlogs.sh"
bash -l "$CURDIR/install_passenger.sh"

