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
  # Start: Package manager Selection
  # clear the screen
  tput clear
  
  # Move cursor to screen location X,Y (top left is 0,0)
  tput cup 5 
  echo "Which package manager do you wish to use:"
  tput sgr0
  
  tput cup 7 3
  echo "1. CocoaPods"
  
  tput cup 8 3
  echo "2. Carthage"
  
  tput cup 9 3
  echo "3. Swift Package Manager (No config required)"
  
  tput bold
  tput cup 12 3
  read -p "Select your choice [1-3] " choice
  
  tput clear
  tput sgr0
  tput rc

  if [[ $choice == 1 ]]; then
    sed -i '' '/#REPLACE_CARTHAGE#/d' Mintfile
    PACKAGE_MANAGER="cocoa"
  elif [[ $choice == 2 ]]; then
    sed -i '' 's|#REPLACE_COCOA#|Carthage/Carthage@0.38.0|g' Mintfile
    sed -i '' '/#REPLACE_COCOA#/d' Mintfile
    touch Cartfile
    touch Cartfile.resolved
    PACKAGE_MANAGER="carthage"
  else
    echo "No additional config required"
  fi
# END: Package manager Selection

  install_current mint
  mint bootstrap
fi

mv ForkApp $1
mv ForkAppTests "$1Tests"
sed -i '' "s/#PROJECT_NAME#/$1/g" project.yml

if [ "$PACKAGE_MANAGER" == "cocoa" ] ;then
  mint run xcodegen
  pod init
  pod install
elif [[ "$PACKAGE_MANAGER" == "carthage" ]]; then
  mint run carthage carthage bootstrap --platform iOS --no-use-binaries --cache-builds
  mint run xcodegen
else
  echo "No Package manager was selected, skipping..."
  mint run xcodegen
fi

# Start: StoryBoard usage selection
# clear the screen
tput clear

# Move cursor to screen location X,Y (top left is 0,0)
tput cup 5 
echo "Do you want to work your layouts through the code:"
tput sgr0
tput cup 7 3
echo "1. Yes (Will remove the reference to the Main.storyboard file and add boilerplate on AppDelegate.swift)"

tput cup 10 3
echo "2. No (Files remains untouched)"

tput bold
tput cup 12 3
read -p "Select your choice [1-2] " storyboard_choice

tput clear
tput sgr0
tput rc

if [ $storyboard_choice == 1 ] ;then
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

  # # Set the filename
  # sceneDelegateFileName='SceneDelegate.swift'

  # # Check the file is exists or not
  # if [ -f $filename ]; then
  #    rm $sceneDelegateFileName
  #    echo "$filename is removed"
  # fi

  sed -i '' 's/return true/let window = UIWindow(frame: UIScreen.main.bounds)\n\tlet mockViewController = ViewController()\n\tmockViewController.view.backgroundColor = .red\n\twindow.rootViewController = mockViewController\n\twindow.makeKeyAndVisible()\n\tself.window = window\n\treturn true/' AppDelegate.swift

  lineNumberSceneDelegates=$(grep -n '// MARK: UISceneSession Lifecycle' AppDelegate.swift | cut -d : -f 1)

  sed -i '' '27,42d' AppDelegate.swift
  echo ""
  echo ""
  echo "Configuration complete!. Remember to completely remove your Main.Storyboard reference and SceneDelegate.swift file, promise to improve this in the future :)"
else
    echo "Configuration complete!."
fi

# END: StoryBoard usage selection
