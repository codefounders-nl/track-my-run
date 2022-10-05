/*
 * Copyright (C) 2022  SLFT
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * trackmyrun is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import QtWebEngine 1.6
import QtWebChannel  1.0
import QtPositioning 5.2

import Example 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'trackmyrun.slft'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('Track My Run')
        }

        Component.onCompleted: {
            myWebChannel.registerObject("qtObject",qtObject);   
        }

        PositionSource {
            id: geoposition
            active: true
            preferredPositioningMethods: PositionSource.SatellitePositioningMethods
            updateInterval:1000
            onPositionChanged:{
                let coordinateObject = {}
                coordinateObject.lat = geoposition.position.coordinate.latitude;
                coordinateObject.lon = geoposition.position.coordinate.longitude;
                let theTime = Date.now();
                coordinateObject.time = theTime
                coordinateObject.delayed = checkIfTimeIsTooLong(coordinateObject, qtObject.trackingDataArray);
                if(coordinateObject.delayed){
                    qtObject.walkingDataArray.push([]);
                }
                
                if(checkIfNeedToAddCoordObject(coordinateObject, qtObject.trackingDataArray)){
                    qtObject.trackingDataArray.push(coordinateObject);
                    qtObject.trackingDataArray = qtObject.trackingDataArray;
                    var lineDataArray = [];
                    lineDataArray.push(coordinateObject.lat);
                    lineDataArray.push(coordinateObject.lon);
                    if(coordinateObject.lat == null){}else{
                    qtObject.walkingDataArray[qtObject.walkingDataArray.length - 1].push(lineDataArray);
                    }
                }else{
                    qtObject.trackingDataArray[qtObject.trackingDataArray.length - 1].time = theTime;

                }
                qtObject.walkingDataArray = qtObject.walkingDataArray;
            }
        }

        WebChannel {
            id: myWebChannel
        }

        QtObject {
            id: qtObject

            signal onRefresh()

            property int zoomFactor : zoomSlider.value
            property double longitude : geoposition.position.coordinate.longitude
            property double latitude : geoposition.position.coordinate.latitude
            property bool centerLockMode : centerLock.checked
            property var trackingDataArray : [{"lat":51.2,"lon":52.2,"time":Date.now()}]
            property var interruptionDataArray : []
            property var walkingDataArray : [[]]
            

            onZoomFactorChanged: onRefresh()
            onLongitudeChanged: onRefresh()
            onLatitudeChanged: onRefresh()
            onCenterLockModeChanged: {
                onRefresh();
                centerLock.checked = centerLockMode;
            }
        }
        MouseArea{
            id: mouseLockArea
            anchors.fill: webEngineView
            z:100
            onPressed: {
                console.log("check op lock");
                mouse.accepted = false;
                centerLock.checked = false;
            }
        }
        WebEngineView {
            id: webEngineView
            webChannel: myWebChannel

            anchors {
                fill: parent 
                bottomMargin: zoomSlider.height + units.gu(6)
                topMargin: header.height
            }

            url: "index.html"

        }
        Slider{

            id: zoomSlider
            maximumValue: 25
            minimumValue: 3
            stepSize: 1
            value: 16
            width: parent.width - centerLock.width - units.gu(5)
            anchors {
                verticalCenter: centerLock.verticalCenter
                left: parent.left
                leftMargin: units.gu(2)
                
            }
            onValueChanged: qtObject.refresh()

        }
        Switch{
            id: centerLock

            checked: true
            anchors{
                bottom: parent.bottom 
                bottomMargin: units.gu(4)
                right: parent.right
                rightMargin: units.gu(2)
            }
        }
    }
        function checkIfTimeIsTooLong(newCoordinateObject, trackingArray){
//        console.log("in time check >>"+newCoordinateObject.time+"<<>>"+trackingArray[trackingArray.length -1].time);
        let difference = newCoordinateObject.time - trackingArray[trackingArray.length -1].time;
//        console.log(difference);
        if(difference > 25000){
            console.log("DELAYED IS");
            return true;
        }
        return false;
    }
    function checkIfNeedToAddCoordObject(newCoordinateObject, trackingArray){
        if(newCoordinateObject.lon == null || newCoordinateObject.lat == null){
            return false;
        }
        let n = newCoordinateObject; let t = trackingArray;
        let distancegpslon = Math.pow((trackingArray[trackingArray.length -1].lon - newCoordinateObject.lon),2);
        let distancegpslat = Math.pow((trackingArray[trackingArray.length -1].lat - newCoordinateObject.lat),2);
        let distance = Math.sqrt(distancegpslat + distancegpslon);
//        if(distance < 0.00001 || distance > 0.1){  // we vermoeden 1 meter OR 10 km
        if(distance < 0.000005){
            return false;
        }
        return true;
    }
}
