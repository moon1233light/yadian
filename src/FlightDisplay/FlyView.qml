/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// 3D Viewer modules
import Viewer3D

Item {
    id: _root

    // ******************** 右侧第二路图传窗口 ********************
    property var    _videoStreamManager:        QGroundControl.videoManager
    property bool   _videoRecording:            _videoStreamManager.recording
    property bool   _videoDecoding:             _videoStreamManager.decoding

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController

    // Properties of UTM adapter
    property bool utmspSendActTrigger: false

    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }

    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
    }

    function dropMessageIndicatorTool() {
        toolbar.dropMessageIndicatorTool();
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
    }

    Item {
        id:                 mapHolder
        anchors.top:        toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
            pipView:                _pipView
            pipMode:                !_mainWindowIsMap
            toolInsets:             customOverlay.totalToolInsets
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
        }

        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
        }

        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                    (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0
        }

        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2 // we need to add one extra layer for map 3d viewer (normally was 1)
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            visible:                !QGroundControl.videoManager.fullScreen
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
        }

        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       widgetLayer
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            visible:            !QGroundControl.videoManager.fullScreen
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      widgetLayer.z + 1
            insetsToView:           widgetLayer.totalToolInsets
            visible:                false
        }

        GuidedActionsController {
            id:                 guidedActionsController
            missionController:  _missionController
            guidedValueSlider:     _guidedValueSlider
        }

        //-- Guided value slider (e.g. altitude)
        GuidedValueSlider {
            id:                 guidedValueSlider
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            z:                  QGroundControl.zOrderTopMost
            visible:            false
        }

        Viewer3D{
            id:                     viewer3DWindow
            anchors.fill:           parent
            visible:false
        }

        // 显示图传按钮
        Rectangle {
            id:                     showPip
            anchors.right:          parent.right
            anchors.margins:        _toolsMargin
            anchors.bottom:         parent.bottom
            height:                 ScreenTools.defaultFontPixelHeight * 2
            width:                  ScreenTools.defaultFontPixelHeight * 2
            radius:                 ScreenTools.defaultFontPixelHeight / 3
            visible:                QGroundControl.videoManager.isStreamSource && !rightVideo.visible
            color:                  Qt.rgba(0,0,0,0.5)
            Image {
                width:              parent.width  * 0.75
                height:             parent.height * 0.75
                sourceSize.height:  height
                source:             "/res/buttonRight.svg"
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                rotation:           180
                anchors.verticalCenter:     parent.verticalCenter
                anchors.horizontalCenter:   parent.horizontalCenter
            }
            MouseArea {
                anchors.fill:   parent
                onClicked:      rightVideo.visible = true
            }
        }
        property real   _pipSize:           parent.width * 0.2
        Rectangle {
            id:                     rightVideo
            width:                  _pipView.width
            height:                 _pipView.height
            color:                  "#222222"
            anchors.right:          parent.right
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            //z:                      QGroundControl.zOrderTopMost
            visible:                QGroundControl.videoManager.isStreamSource //&& globals.videoVisible

            QGCLabel {
                text:               QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue ? "等待视频中" : "视频不可用"
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              "white"
                anchors.centerIn:   parent
                visible:            !(QGroundControl.videoManager.decoding)
            }

            QGCVideoBackground {
                id:             thermalVideo
                objectName:     "thermalVideo"
                anchors.fill:   parent
                //receiver:       QGroundControl.videoManager.thermalVideoReceiver
            }

            MouseArea {
                id: video02MouseArea
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    // console.log("video02MouseArea Mouse entered")
                }
                onExited: {
                    // console.log("video02MouseArea Mouse exited")
                }
            }

            // 隐藏图传按钮
            QGCColoredImage {
                source:         "/InstrumentValueIcons/cheveron-down.svg"
                mipmap:         true
                color:          "white"
                fillMode:       Image.PreserveAspectFit
                anchors.right:   parent.right
                anchors.bottom: parent.bottom
                visible:        (ScreenTools.isMobile || video02MouseArea.containsMouse)
                height:         ScreenTools.defaultFontPixelHeight * 1.5
                width:          ScreenTools.defaultFontPixelHeight * 1.5
                rotation:       -90
                sourceSize.height:  height
                opacity:        0.5
                MouseArea {
                    //anchors.margins: -ScreenTools.defaultFontPixelHeight / 2
                    anchors.fill:   parent
                    onClicked:      rightVideo.visible = false
                }
            }
        }
    }
}
