@echo off
ECHO Creating project structure...

REM Create the assets directory and a placeholder file
IF NOT EXIST assets mkdir assets
cd assets
ECHO This is a placeholder file > placeholder.txt

REM Create the font directory
IF NOT EXIST fonts mkdir fonts
cd fonts

REM Download Scheherazade font files if they don't exist
IF NOT EXIST ScheherazadeNew-Regular.ttf (
  ECHO Downloading Scheherazade font files...
  curl -L -o ScheherazadeNew-Regular.ttf https://github.com/silnrsi/scheherazade/raw/master/source/ScheherazadeNew-Regular.ttf
  curl -L -o ScheherazadeNew-Bold.ttf https://github.com/silnrsi/scheherazade/raw/master/source/ScheherazadeNew-Bold.ttf
)

cd ..
cd ..

REM Add web support to the project
ECHO Adding web support to the project...
flutter create --platforms=web .

REM Get dependencies
ECHO Getting dependencies...
flutter pub get

ECHO Project setup complete. You can now run 'flutter run -d chrome'
