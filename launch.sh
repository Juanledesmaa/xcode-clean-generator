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

if [ "$2" != "" ]; then
    echo "Dependency manager: $2"
    if [ "$2" == "cocoa" ]; then
    PACKAGE_MANAGER="1"
    elif [ "$2" == "carthage" ]; then
    PACKAGE_MANAGER="2"
    else
    echo "No valid name for package manager, proceeding with Swift Package Manager (No config required)"
    PACKAGE_MANAGER="3"
    fi
else
    echo "Package manager selection required!"
    exit 1
fi

if [ "$3" != "" ]; then
    echo "With Storyboard: $3"
    if [ "$3" == "no-storyboard" ]; then
    WITH_STORYBOARD="0"
    else
    WITH_STORYBOARD="1"
    fi
else
    echo "Keeping Storyboard, Files will remain untouched!"
fi

# Download template project from github
git clone "https://github.com/Juanledesmaa/xcode-clean-generator.git" $1
cd $1
rm -Rf .git 

if [ -e "Mintfile" ]; then
  if [[ "$PACKAGE_MANAGER" == "1" ]]; then
    sed -i '' '/#REPLACE_CARTHAGE#/d' Mintfile
  elif [[ "$PACKAGE_MANAGER" == "2" ]]; then
    sed -i '' 's|#REPLACE_CARTHAGE#|Carthage/Carthage@0.38.0|g' Mintfile
    touch Cartfile
    touch Cartfile.resolved
  else
    sed -i '' '/#REPLACE_CARTHAGE#/d' Mintfile
    echo "No additional config required"
  fi
# END: Package manager Selection

  install_current mint
  mint bootstrap
fi

mv ForkApp $1
mv ForkAppTests "$1Tests"
sed -i '' "s/#PROJECT_NAME#/$1/g" project.yml

if [[ "$PACKAGE_MANAGER" == "1" ]] ;then
  mint run xcodegen
  pod init
  pod install
elif [[ "$PACKAGE_MANAGER" == "2" ]]; then
  mint run carthage carthage bootstrap --platform iOS --no-use-binaries --cache-builds
  mint run xcodegen
else
  echo "No Package manager was selected, skipping..."
  mint run xcodegen
fi

if [[ "$WITH_STORYBOARD" == "0" ]] ;then
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
