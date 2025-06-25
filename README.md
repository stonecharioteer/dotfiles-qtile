# Qtile Dotfiles

```bash
mkdir -p ~/Pictures/screenshots
sudo apt install rofi
sudo mkdir -p /opt/qtile
sudo chown /opt/qtile stonecharioteer:stonecharioteer
python -m venv /opt/qtile
source /opt/qtile/bin/activate.fish
pip install qtile psutil
ln -s $PWD/install/rofi $HOME/.config/rofi
sudo cp install/qtile.desktop /usr/share/xsessions/
sudo chmod a+rx /opt/qtile/bin/qtile /opt/qtile/bin/python
```
