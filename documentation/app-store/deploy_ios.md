# [Build and release an iOS app](https://docs.flutter.dev/deployment/ios)

---

title: Build and release an iOS app
description: How to release a Flutter app to the App Store.
short-title: iOS

---

This guide provides a step-by-step walkthrough of releasing a Flutter app to the [App Store](https://developer.apple.com/app-store/submissions/) and [TestFlight](https://developer.apple.com/testflight/).

## Preliminaries

Xcode is required to build and release your app. You must use a device running macOS to follow this guide.

Before beginning the process of releasing your app, ensure that it meets Apple's [App Review Guidelines](https://developer.apple.com/app-store/review/).

To publish your app to the App Store, you must first enroll in the [Apple Developer Program](https://developer.apple.com/programs/).
You can read more about the various membership options in Apple's [Choosing a Membership](https://developer.apple.com/support/compare-memberships/) guide.

## Video overview

YouTube [Release an iOS app built with Flutter in 7 steps](https://www.youtube.com/watch?v=iE2bpP56QKc)

### Transcription "Release an iOS app built with Flutter in 7 steps" video

LEIGHA JARETT: Hi there, Flutter developer. If you're watching this video, I'm going to assume you've already created a Flutter app that looks and feels great on iOS, and now you're ready to deploy it to the App Store, like the Wondrous app that I have here.

Before we jump in, there's a few prerequisites that you'll need to have. First, to build and release an iOS app, make sure that you have Xcode installed on your Mac computer. Second, to publish your app to the App Store, make sure that your app adheres to the App Store review guidelines. And finally, you'll need to be enrolled in the Apple Developer Program. No worries if you're not. You can find a link to sign up below.

Now that we've got those prereqs out of the way, let's get started.

Start by registering your app's bundle ID. You can register a bundle ID with your Apple development team by going to Apple's Identifiers page under Certificates, IDs, and Profiles, and then filling out the details of your app. If you haven't heard of a bundle ID before, it's a unique identifier for your app. Apple encourages reverse domain-name notation to avoid conflicts with other apps. Let's say you work at a company where you use the domain mycompany.com. In that case, all of your app bundle IDs might start with com.mycompany. If you created an app called myapp, the entire bundle ID could look something like this, com.mycompany.myapp.

#### Step 2: Create a record in App Store Connect

Once that's done, create a record for your app in App Store Connect, which you'll use to submit and manage your app. Head over to the Apps page under App Store Connect and click the Plus button to create a new record. Next, fill in the details like the name and the target platform. Then select the bundle ID that you registered. Now that you're all set with your record,

#### Step 3: Modify your Xcode settings

head over to Xcode to double check some project settings. Oh, and by the way, if you're looking for more information on how Flutter works with Xcode, then check out our video Flutter for iOS Developers. Open up the relevant iOS files in Xcode by right clicking on the iOS folder in your Flutter app project, or run this command on the terminal from your project's root directory. To view your app settings, open up the runner target. Take a look at the General tab. Add a category and a display name for your app, and check the bundle identifier. If you don't explicitly set your org, Flutter fills it in with a placeholder reverse domain, com.example, plus the name of your app. Quick tip-- you can save time and skip this step by passing your reverse domain org as a parameter when you create a Flutter project, or just modify the settings in VS Code so all your new Flutter apps will use that org domain. Either way, you'll need to make sure that this bundle identifier matches the one you registered earlier. In addition to confirming the identity of your app, make sure that the deployment information is correct. Now specify the minimum version of iOS that your app users must have. If your app or plugins make use of newer APIs, you'll need to make sure that this meets the minimum requirement. Next up, head to the Signing and Capabilities tab.

Before we talk through the settings, it's helpful to understand just what code signing is. Code signing assures users that your app is from a known and approved source and hasn't been tampered with. Before your app can be run on a device or submitted to the App Store, its binary must be signed with a certificate that's issued by Apple. The certificate basically says that you are who you say you are, and when you're ready to distribute your app, a provisioning profile is used to tie your certificates to your app ID and authorizes your app to use particular services. Thankfully, Xcode has a setting to automatically manage app signing for you, and Flutter projects have it enabled by default.

To use it, specify the development team that should publish the app.

#### Step 4: Add your app icon

Now on to adding your app icon. You may have noticed that Flutter creates a placeholder icon, the infamous Flutter F. In Xcode, click on Assets in the runner project. Here you see the different sized icons based on their usage. Historically, developers would use an app-icon generator to create all the different file sizes based on a single input. But if you're using Xcode 14 or later, you can just change the setting to use a single 1,024 by 1,024 image and upload one icon.

#### Step 5: Update your build version

OK, so we have our settings finished up in Xcode. Let's head back to our Flutter repository. Before you build an archive for a new version of your app, you'll want to increment its version number. In iOS, this is tracked under the CFBundleVersion Core Foundation key. This key is a machine-readable string composed of one to three period-separated integers, such as 2.0.13. The first number represents a pretty major overhaul of the app, like changing the design system. The second number likely represents minor changes, like a few new features. And the last number represents a patch, so pretty minor changes like little bug fixes. In Flutter apps, we change the version by modifying the pubspec.yaml file. You can also optionally include a build number to track different builds during development. Finally, you're ready to create a build archive and upload it

#### Step 6: Create a build archive

to App Store Connect. To build an app means to compile the source code and app assets into something that can be run or distributed. When you're debugging and testing your app, you're usually running your app. Whether you're working in an IDE and pressing the Run button or using the flutter run command, both processes create a dot app bundle in debug mode and launches it on the connected simulator or device. Debug mode means that the compilation is optimized for fast development cycles. So you can quickly make changes, and by the magic of Flutter's hot reload, you can see those changes reflected almost immediately on the device. When it's time to distribute your app, you'll want to build in release mode. Release mode compilation is optimized for fast startup, fast execution, and small package sizes. To build your app in release mode, run `flutter build release`. This creates a dot app bundle which is good for local development and testing, but to distribute the app, you'll need a dot ipa. In Xcode, an app bundle is used to create an archive, which is then used to create an IPA. In Flutter, we do the same thing, only we've tried to simplify this process by creating a single command, `flutter build ipa`. When building an IPA, you have the option to prepare your app to be distributed inside or outside of the App Store. By default, we prepare the IPA for the App Store, but you can use the `export-method` flag to change this. For example, you may want to use the enterprise export method, which allows you to distribute your app to users in your organization. You can also consider adding the `obfuscate` and `split-debug-info` flags to obfuscate your Dart code so that it's more difficult to reverse engineer. Once you've run the `build ipa` command, you can find the Xcode build archive in your project's `build/ios/archive` directory and the dot IPA file in the `build/ios/ipa`. Now we're in the home stretch.

#### Step 7: Add to App Store Connect

It's time to add your IPA file to App Store Connect. There are a few different ways to do this, but the easiest is to use the Apple Transport macOS app. Drag and drop the IPA into the Transport app and wait for it to process. Once it's all ready, deliver it to App Store Connect. Over in App Store Connect, you can choose whether or not you want to deploy your app to the App Store or to TestFlight. TestFlight lets you push your apps to internal and external testers before making it available to a larger audience. Just create your groups of testers to get started. Keep in mind if you choose to invite external testers, your app is submitted to beta app review, which means that you may need to wait a few days before your app becomes available to testers. Testers can install the TestFlight app on their device and use it to install your app and share feedback. When you're ready to release your app to the world, complete all the required fields and click Add for Review. Apple will notify you when the review process is complete and your app is live in the App Store.

And that's how you deploy your Flutter app in the App Store in seven steps. For more details on all the steps that we went through today and ways that you can automate the process, check out the step-by-step guide included in the video description. I'm Leigha Thanks for watching, and I can't wait to see your Flutter app in the App Store.

## Register your app on App Store Connect

Manage your app's life cycle on [App Store Connect](https://developer.apple.com/support/app-store-connect/) (formerly iTunes Connect).
You define your app name and description, add screenshots, set pricing, and manage releases to the App Store and TestFlight.

Registering your app involves two steps: registering a unique Bundle ID, and creating an application record on App Store Connect.

For a detailed overview of App Store Connect, see the [App Store Connect](https://developer.apple.com/support/app-store-connect/) guide.

### Register a Bundle ID

Every iOS application is associated with a Bundle ID, a unique identifier registered with Apple. To register a Bundle ID for your app, follow these steps:

1. Open the [App IDs](https://developer.apple.com/account/ios/identifier/bundle) page of your developer account.
1. Click **+** to create a new Bundle ID.
1. Enter an app name, select **Explicit App ID**, and enter an ID.
1. Select the services your app uses, then click **Continue**.
1. On the next page, confirm the details and click **Register** to register your Bundle ID.

### Create an application record on App Store Connect

Register your app on App Store Connect:

1. Open [App Store Connect](https://developer.apple.com/support/app-store-connect//) in your browser.
1. On the App Store Connect landing page, click **My Apps**.
1. Click **+** in the top-left corner of the My Apps page, then select **New App**.
1. Fill in your app details in the form that appears. In the Platforms section, ensure that iOS is checked. Since Flutter does not currently support tvOS, leave that checkbox unchecked. Click **Create**.
1. Navigate to the application details for your app and select **App Information** from the sidebar.
1. In the General Information section, select the Bundle ID you registered in the preceding step.

For a detailed overview, see [Add an app to your account](https://help.apple.com/app-store-connect/#/dev2cd126805).

## Review Xcode project settings

This step covers reviewing the most important settings in the Xcode workspace.
For detailed procedures and descriptions, see [Prepare for app distribution](https://help.apple.com/xcode/mac/current/#/dev91fe7130a).

Navigate to your target's settings in Xcode:

1. Open the default Xcode workspace in your project by running `open ios/Runner.xcworkspace` in a terminal window from your Flutter project directory.
2. To view your app's settings, select the **Runner** target in the Xcode navigator.

Verify the most important settings.

In the **Identity** section of the **General** tab:

`Display Name`
: The display name of your app.

`Bundle Identifier`
: The App ID you registered on App Store Connect.

In the **Signing & Capabilities** tab:

`Automatically manage signing`
: Whether Xcode should automatically manage app signing and provisioning. This is set `true` by default, which should be sufficient for most apps. For more complex scenarios, see the [Code Signing Guide](https://developer.apple.com/library/content/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html).

`Team`
: Select the team associated with your registered Apple Developer account. If required, select **Add Account...**, then update this setting.

In the **Deployment** section of the **Build Settings** tab:

`iOS Deployment Target`
: The minimum iOS version that your app supports.
Flutter supports iOS 12 and later. If your app or plugins include Objective-C or Swift code that makes use of APIs newer than iOS 12, update this setting to the highest required version.

The **General** tab of your project settings should resemble
the following:

![Xcode Project Settings](https://docs.flutter.dev/assets/images/docs/releaseguide/xcode_settings.png)

For a detailed overview of app signing, see [Create, export, and delete signing certificates](https://help.apple.com/xcode/mac/current/#/dev154b28f09).

## Updating the app's deployment version

If you changed `Deployment Target` in your Xcode project,
open `ios/Flutter/AppframeworkInfo.plist` in your Flutter app
and update the `MinimumOSVersion` value to match.

## Add an app icon

When a new Flutter app is created, a placeholder icon set is created. This step covers replacing these placeholder icons with your app's icons:

1. Review the [iOS App Icon](https://developer.apple.com/design/human-interface-guidelines/app-icons/) guidelines and, in particular, the advice on [creating light, dark, and tinted](https://developer.apple.com/design/human-interface-guidelines/app-icons#iOS-iPadOS) icons for your app.
2. In the Xcode project navigator, select `Assets.xcassets` in the `Runner` folder. Update the placeholder icons with your own app icons.
3. Verify the icon has been replaced by running your app using `flutter run`.

## Add a launch image

Similar to the app icon,
you can also replace the placeholder launch image:

1. In the Xcode project navigator,
   select `Assets.xcassets` in the `Runner` folder.
   Update the placeholder launch image with your own launch image.
1. Verify the new launch image by hot restarting your app.
   (Don't use `hot reload`.)

## Create a build archive and upload to App Store Connect

During development, you've been building, debugging, and testing with _debug_ builds. When you're ready to ship your app to users on the App Store or TestFlight, you need to prepare a _release_ build.

### Update the app's build and version numbers

The default version number of the app is `1.0.0`. To update it, navigate to the `pubspec.yaml` file and update the following line:

```yaml
version: 1.0.0+1
```

The version number is three numbers separated by dots, such as `1.0.0` in the example above, followed by an optional build number such as `1` in the example above, separated by a `+`.

Both the version and the build number can be overridden in `flutter build ipa` by specifying `--build-name` and `--build-number`, respectively.

In iOS, `build-name` uses `CFBundleShortVersionString` while `build-number` uses `CFBundleVersion`. Read more about iOS versioning at [Core Foundation Keys](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html) on the Apple Developer's site.

You can also override the `pubspec.yaml` build name and number in Xcode:

1. Open `Runner.xcworkspace` in your app's `ios` folder.
1. Select **Runner** in the Xcode project navigator, then select the
   **Runner** target in the settings view sidebar.
1. In the Identity section, update the **Version** to the user-facing
   version number you wish to publish.
1. In the Identity section, update the **Build** identifier to a unique
   build number used to track this build on App Store Connect.
   Each upload requires a unique build number.

### Create an app bundle

Run `flutter build ipa` to produce an Xcode build archive (`.xcarchive` file)
in your project's `build/ios/archive/` directory and an App Store app
bundle (`.ipa` file) in `build/ios/ipa`.

> Antes de ejecutar `flutter build ipa`, asegúrate de que tu proyecto Flutter esté en un estado limpio. Puedes hacerlo ejecutando `flutter clean` y `flutter pub get`.
> Además, puedes pasarle como argumento la Access Token de Mapbox si lo necesitas con el comando `flutter build ipa --release --dart-define=MAPBOX_ACCESS_TOKEN=tu_token_de_mapbox`.

Consider adding the `--obfuscate` and `--split-debug-info` flags to
[obfuscate your Dart code](https://docs.flutter.dev/deployment/obfuscate) to make it more difficult
to reverse engineer.

If you are not distributing to the App Store, you can optionally choose a different [export method](https://help.apple.com/xcode/mac/current/#/dev31de635e5) by adding the option `--export-method ad-hoc`, `--export-method development` or `--export-method enterprise`.

> On versions of Flutter where `flutter build ipa --export-method` is unavailable, open `build/ios/archive/MyApp.xcarchive` and follow the instructions below to validate and distribute the app from Xcode.

### Upload the app bundle to App Store Connect

Once the app bundle is created, upload it to
[App Store Connect](https://developer.apple.com/support/app-store-connect/) by either:

1. Install and open the [Apple Transport macOS app](https://appstoreconnect.apple.com/). Drag and drop the `build/ios/ipa/*.ipa` app bundle into the app.

2. Or upload the app bundle from the command line by running:

   ```bash
   xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey your_api_key --apiIssuer your_issuer_id
   ```

   Run `man altool` for details about how to authenticate with the App Store Connect API key.

3. Or open `build/ios/archive/MyApp.xcarchive` in Xcode.

   Click the **Validate App** button. If any issues are reported,
   address them and produce another build. You can reuse the same
   build ID until you upload an archive.

   After the archive has been successfully validated, click
   **Distribute App**.

   > When you export your app at the end of **Distribute App**, Xcode will create a directory containing an IPA of your app and an `ExportOptions.plist` file. You can create new IPAs with the same options without launching Xcode by running `flutter build ipa --export-options-plist=path/to/ExportOptions.plist`. See `xcodebuild -h` for details about the keys in this property list.

4. You can follow the status of your build in the
   Activities tab of your app's details page on
   [App Store Connect](https://appstoreconnect.apple.com/).
   You should receive an email within 30 minutes notifying you that
   your build has been validated and is available to release to testers
   on TestFlight. At this point you can choose whether to release
   on TestFlight, or go ahead and release your app to the App Store.

   For more details, see [Upload an app to App Store Connect](https://help.apple.com/xcode/mac/current/#/dev442d7f2ca).

## Create a build archive with Codemagic CLI tools

This step covers creating a build archive and uploading
your build to App Store Connect using Flutter build commands
and [Codemagic CLI Tools](https://github.com/codemagic-ci-cd/cli-tools) executed in a terminal in the Flutter project directory. This allows you to create a build archive with full control of distribution certificates in a temporary keychain isolated from your login keychain.

1. Install the Codemagic CLI tools:

   ```bash
   pip3 install codemagic-cli-tools
   ```

2. You'll need to generate an [App Store Connect API Key](https://appstoreconnect.apple.com/access/api) with App Manager access to automate operations with App Store Connect. To make subsequent commands more concise, set the following environment variables from the new key: issuer id, key id, and API key file.

   ```bash
   export APP_STORE_CONNECT_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
   export APP_STORE_CONNECT_KEY_IDENTIFIER=ABC1234567
   export APP_STORE_CONNECT_PRIVATE_KEY=`cat /path/to/api/key/AuthKey_XXXYYYZZZ.p8`
   ```

3. You need to export or create an iOS Distribution certificate to code sign and package a build archive.

   If you have existing [certificates](https://developer.apple.com/account/resources/certificates), you can export the private keys by executing the following command for each certificate:

   ```bash
   openssl pkcs12 -in <certificate_name>.p12 -nodes -nocerts | openssl rsa -out cert_key
   ```

   Or you can create a new private key by executing the following command:

   ```bash
   ssh-keygen -t rsa -b 2048 -m PEM -f cert_key -q -N ""
   ```

   Later, you can have CLI tools automatically create a new iOS Distribution from the private key.

4. Set up a new temporary keychain to be used for code signing:

   ```bash
   keychain initialize
   ```

   > Restore Login Keychain!
   > After running `keychain initialize` you **must** run the following:
   >
   > `keychain use-login`
   >
   > This sets your login keychain as the default to avoid potential
   > authentication issues with apps on your machine.

5. Fetch the code signing files from App Store Connect:

   ```bash
   app-store-connect fetch-signing-files $(xcode-project detect-bundle-id) \
       --platform IOS \
       --type IOS_APP_STORE \
       --certificate-key=@file:/path/to/cert_key \
       --create
   ```

   Where `cert_key` is either your exported iOS Distribution certificate private key or a new private key which automatically generates a new certificate. The certificate will be created from the private key if it doesn't exist in App Store Connect.

6. Now add the fetched certificates to your keychain:

   ```bash
   keychain add-certificates
   ```

7. Update the Xcode project settings to use fetched code signing profiles:

   ```bash
   xcode-project use-profiles
   ```

8. Install Flutter dependencies:

   ```bash
   flutter packages pub get
   ```

9. Install CocoaPods dependencies:

   ```bash
   find . -name "Podfile" -execdir pod install \;
   ```

10. Build the Flutter the iOS project:

    ```bash
    flutter build ipa --release \
        --export-options-plist=$HOME/export_options.plist
    ```

    Note that `export_options.plist` is the output of the `xcode-project use-profiles` command.

11. Publish the app to App Store Connect:

    ```bash
    app-store-connect publish \
        --path $(find $(pwd) -name "*.ipa")
    ```

12. As mentioned earlier, don't forget to set your login keychain as the default to avoid authentication issues with apps on your machine:

    ```bash
    keychain use-login
    ```

    You should receive an email within 30 minutes notifying you that
    your build has been validated and is available to release to testers
    on TestFlight. At this point you can choose whether to release
    on TestFlight, or go ahead and release your app to the App Store.

## Release your app on TestFlight

[TestFlight](https://developer.apple.com/testflight/) allows developers to push their apps
to internal and external testers. This optional step covers releasing your build on TestFlight.

1. Navigate to the TestFlight tab of your app's application
   details page on [App Store Connect](https://appstoreconnect.apple.com/).
1. Select **Internal Testing** in the sidebar.
1. Select the build to publish to testers, then click **Save**.
1. Add the email addresses of any internal testers.
   You can add additional internal users in the **Users and Roles**
   page of App Store Connect,
   available from the dropdown menu at the top of the page.

For more details, see [Distribute an app using TestFlight](https://help.apple.com/xcode/mac/current/#/dev2539d985f).

## Release your app to the App Store

When you're ready to release your app to the world,
follow these steps to submit your app for review and
release to the App Store:

1. Select **Pricing and Availability** from the sidebar of your app's application details page on [App Store Connect](https://appstoreconnect.apple.com/) and complete the required information.
1. Select the status from the sidebar. If this is the first release of this app, its status is **1.0 Prepare for Submission**. Complete all required fields.
1. Click **Submit for Review**.

Apple notifies you when their app review process is complete. Your app is released according to the instructions you specified in the **Version Release** section.

For more details, see [Distribute an app through the App Store](https://help.apple.com/xcode/mac/current/#/dev067853c94).

## Troubleshooting

The [Distribute your app](https://help.apple.com/xcode/mac/current/#/devac02c5ab8) guide provides a detailed overview of the process of releasing an app to the App Store.
