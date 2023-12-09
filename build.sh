#!/bin/sh

#  build.sh
#  DiskGroupSwitcher
#
#  Created by kelvinwong on 2023/12/9.
#  

if [[ "$1" = "help" ]] || [[ "$1" = "--help" ]]  || [[ "$1" = "--?" ]]; then
   echo "Sample:"
   echo "./build.sh"
   echo "./build.sh version up"
   echo "./build.sh version up major"
   echo "./build.sh version up minor"
   echo "./build.sh version up revision"
   echo
   exit 0
fi

versionPos="revision"
versionChange=0
if [[ "$1 $2" = "version up" ]]; then
   versionChange=1
   if [[ "$3" = "major" ]]; then
       versionPos="major"
   elif [[ "$3" = "minor" ]]; then
       versionPos="minor"
   else
       versionPos="revision"
   fi
fi

PROJ=`ls -1 . | grep ".xcodeproj$" | awk -F'.' '{print $1}'`
PREV_VERSION=`less DiskGroupSwitcher.xcodeproj/project.pbxproj | grep "MARKETING_VERSION" | head -1 | tr ';' ' ' | awk -F' ' '{print $NF}'`
dots=`echo "${PREV_VERSION}" | grep -o "\." | wc -l | bc`
if [[ $dots -eq 1 ]]; then
  PREV_VERSION="${PREV_VERSION}.0"
fi

if [[ $versionChange -eq 1 ]]; then
    if [[ "$versionPos" = "major" ]]; then
        NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1+1".0.0"}'`
    elif [[ "$versionPos" = "minor" ]]; then
        NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1"."$2+1".0"}'`
    else
        NEW_VERSION=`echo $PREV_VERSION | awk -F'.' '{print $1"."$2"."$3+1}'`
    fi
else
    NEW_VERSION=$PREV_VERSION
fi

BUILD_VERSION=`date '+%Y%m%dT%H%M'`

echo "Current version: $PREV_VERSION"
echo "   Next version: $NEW_VERSION"
echo "  Build version: $BUILD_VERSION"

if [[ "$NEW_VERSION" != "$PREV_VERSION" ]]; then
    sed -i .bak -e 's/MARKETING_VERSION = .*/MARKETING_VERSION = '$NEW_VERSION';/' ${PROJ}.xcodeproj/project.pbxproj; rm -f ${PROJ}.xcodeproj/project.pbxproj.bak
fi
sed -i .bak -e 's/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = "'$BUILD_VERSION'";/' ${PROJ}.xcodeproj/project.pbxproj; rm -f ${PROJ}.xcodeproj/project.pbxproj.bak

## build xcarchive
rm -rf build/archive
mkdir -p build/archive
xcodebuild -scheme ${PROJ} -project ./${PROJ}.xcodeproj -configuration Release -destination 'generic/platform=macOS' -archivePath ./build/archive/${PROJ}.xcarchive archive
if [[ $? -eq 0 ]]; then
    ## build app bundle
    rm -rf build/output
    mkdir -p build/output
    xcodebuild -exportArchive -archivePath build/archive/${PROJ}.xcarchive -exportPath build/output -exportOptionsPlist build/config/export.plist
    
    if [[ $? -eq 0 ]] && [[ -d build/output/${PROJ}.app ]] && [[ -f build/output/${PROJ}.app/Contents/MacOS/${PROJ} ]]; then
        ## get package ready
        rm -rf build/release/$BUILD_VERSION
        mkdir -p build/release/$BUILD_VERSION
        cp -R build/output/${PROJ}.app build/release/${BUILD_VERSION}/
        
        ls -l build/output/${PROJ}.app build/release/${BUILD_VERSION}/
        
        rm -rf /tmp/tmp.dmg
        hdiutil create /tmp/tmp.dmg -ov -volname "${PROJ}" -fs HFS+ -srcfolder build/release/${BUILD_VERSION}/
        
        hdiutil convert /tmp/tmp.dmg -format UDZO -o build/release/${BUILD_VERSION}/${PROJ}_${NEW_VERSION}_${BUILD_VERSION}.dmg
        rm -rf build/release/${BUILD_VERSION}/${PROJ}.app
        
        if [[ -f build/release/${BUILD_VERSION}/${PROJ}_${NEW_VERSION}_${BUILD_VERSION}.dmg ]]; then
        
            ## git commit && push
            git status
            GIT_BRANCH=`git status | grep "On branch" | head -1 | awk -F' ' '{print $NF}'`
            CURRENT_VERSION="${NEW_VERSION}.${BUILD_VERSION}"
            
            EXIST_TAG=`git ls-remote --tags origin | tr '/' ' ' | awk -F' ' '{print $NF}' | grep $CURRENT_VERSION`
            if [[ "$EXIST_TAG" != "" ]]; then
                echo "$CURRENT_VERSION already exist in git repository. Aborted following build steps to avoid duplication."
                echo
                exit -1
            fi
            
            if [[ "$GIT_BRANCH" != "$CURRENT_VERSION" ]]; then
                git branch $CURRENT_VERSION
                git checkout $CURRENT_VERSION
            fi
            #git add build/release/${BUILD_VERSION}/
            git commit -am "build version $CURRENT_VERSION"
            if [[ $? -eq 0 ]]; then
                git push --set-upstream origin $CURRENT_VERSION
                if [[ $? -ne 0 ]]; then
                   exit -1
                fi
            fi
            
            # RELEASE

            GH=`which gh`
            if [[ "$GH" != "" ]]; then
                gh pr status
                gh pr create --title "$CURRENT_VERSION" --body "**Full Changelog**: https://github.com/kelvinjjwong/$PROJ/compare/$PREV_VERSION...$CURRENT_VERSION"
                gh pr list
                GH_PR=`gh pr list | tail -1 | tr '#' ' ' | awk -F' ' '{print $1}'`
                gh pr merge $GH_PR -m
                if [[ $? -ne 0 ]]; then
                    exit -1
                fi
                gh pr status
                git pull
                git checkout master
                git pull
                gh release create $CURRENT_VERSION build/release/${BUILD_VERSION}/${PROJ}_${NEW_VERSION}_${BUILD_VERSION}.dmg --generate-notes
                if [[ $? -ne 0 ]]; then
                    exit -1
                fi
            else
                echo "If success, you can publish new release by tagging new version [$CURRENT_VERSION] in git repository"
                echo "https://github.com/kelvinjjwong/$PROJ/releases"
                echo "with auto markdown release note"
                echo "**Full Changelog**: https://github.com/kelvinjjwong/$PROJ/compare/$PREV_VERSION...$CURRENT_VERSION"
                echo
                echo "OR install GitHub CLI to automate these steps:"
                echo "brew install gh"
                echo "https://cli.github.com"
                echo
            fi
        else
            echo "unable to create DMG at build/release/${BUILD_VERSION}/${PROJ}_${NEW_VERSION}_${BUILD_VERSION}.dmg"
        fi
    else
        echo "build macOS app bundle exit code: $?"
        echo "or unable to create app bundle at build/output/${PROJ}.app"
    fi
else
    echo "build xcarchive exit code: $?"
    echo "or unable to create xcarchive at build/archive"
fi


