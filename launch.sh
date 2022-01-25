#!/bin/bash

function install_current {
  echo "trying to update $1"
  brew upgrade $1 || brew install $1 || true
  brew link $1
}

if [ "$1" != "" ]; then
    echo "Project name: $1"
else
    echo "Project name required!"
    exit 1
fi

# Download template project from github
git clone "https://github.com/Juanledesmaa/xcode-clean-generator.git" $1
cd $1
rm -Rf .git 

if [ -e "Mintfile" ]; then
  install_current mint
  mint bootstrap
fi

mv ForkApp $1
mv ForkAppTests "$1Tests"
sed -i '' "s/#PROJECT_NAME#/$1/g" project.yml
mint run carthage carthage bootstrap --platform iOS --no-use-binaries --cache-builds
mint run xcodegen


echo -n "Do you want to remove the Main.Storyboard and work your view through code (y/n)? "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
  # Script to remove Main.Storyboard if needed

  cd $1
  cd Resources/Storyboards/Base.lproj

  # # Set the filename
  # filename='Main.storyboard'

  # # Check the file is exists or not
  # if [ -f $filename ]; then
  #    rm $filename
  #    echo "$filename is removed"
  # fi

  plutil -convert xml1 ../../Metadata/Info.plist
  plutil -lint ../../Metadata/Info.plist
  plutil -remove UIMainStoryboardFile ../../Metadata/Info.plist
  plutil -remove UIApplicationSceneManifest ../../Metadata/Info.plist

  cd ../../../Sources

  # Set the filename
  sceneDelegateFileName='SceneDelegate.swift'

  # Check the file is exists or not
  if [ -f $filename ]; then
     rm $sceneDelegateFileName
     echo "$filename is removed"
  fi

  sed -i '' 's/return true/let window = UIWindow(frame: UIScreen.main.bounds)\n\tlet mockViewController = ViewController()\n\tmockViewController.view.backgroundColor = .red\n\twindow.rootViewController = mockViewController\n\twindow.makeKeyAndVisible()\n\tself.window = window\n\treturn true/' AppDelegate.swift

  lineNumberSceneDelegates=$(grep -n '// MARK: UISceneSession Lifecycle' AppDelegate.swift | cut -d : -f 1)

  echo $lineNumberSceneDelegates

  sed -i '' '27,42d' AppDelegate.swift
  echo ""
  echo ""
  echo "Configuration complete!. Remember to completely remove your Main.Storyboard reference and SceneDelegate.swift file, I'll promise to improve this in the future ;)"
else
    echo "Configuration complete!."
fi



