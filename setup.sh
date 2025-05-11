# colors functions
red() {
    echo -e "\033[31m$1\033[0m"
}
green() {
    echo -e "\033[32m$1\033[0m"
}
yellow() {
    echo -e "\033[33m$1\033[0m"
}
blue() {
    echo -e "\033[34m$1\033[0m"
}
magent() {
    echo -e "\033[35m$1\033[0m"
}
cyan() {
    echo -e "\033[36m$1\033[0m"
}
bold() {
    echo -e "\033[1m$1\033[0m"
}


set -e

green "📦 Setting up the environment..."
bold "> sudo apt install python3-tk -y"
sudo apt install python3-tk -y
bold "> python -m venv tp2_venv"
python -m venv tp2_venv

bold "> sudo apt-get install gcc-multilib -y"
sudo apt-get install gcc-multilib -y

bold "> sudo apt install g++ gfortran libgfortran5 zlib1g:i386 libstdc++6:i386 libgfortran5:i386 -y (For msl-lib)"
sudo apt install g++ gfortran libgfortran5 zlib1g:i386 libstdc++6:i386 libgfortran5:i386 -y

bold "> source tp2_venv/bin/activate"
source tp2_venv/bin/activate

bold "> pip install -r requirements.txt"
pip install -r requirements.txt

