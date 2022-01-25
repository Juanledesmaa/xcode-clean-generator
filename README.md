## Prerequisites ###
Install [Homebrew](https://brew.sh/)

## 🚀 Launch Manual 101 📱 ##

### Parameters

#### 1. `NameOfYourApp`: Replace with whichever name you would like for your project

#### 2. `PackageManager`: Options are: `cocoa`, `carthage`, `none`. You could use none if you would like to use spm on xcode

#### 2. `no-storyboard`: Must be passed as literal `no-storyboard` if the parameter is not passed we will just ignore and keep the storyboard file.

#### So an example will look like this:

```
curl -L https://raw.githubusercontent.com/Juanledesmaa/xcode-clean-generator/main/launch.sh | bash -s -- NameOfYourApp cocoa no-storyboard
```

That's all folk! ❤

Thanks for your time! Any contribution is welcome.
