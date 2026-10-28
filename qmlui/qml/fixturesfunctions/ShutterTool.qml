/*
  Q Light Controller Plus
  ShutterTool.qml

  Copyright (c) Massimo Callegari

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0.txt

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import QtQuick

import org.qlcplus.classes 1.0
import "."

Rectangle
{
    id: toolRoot
    width: UISettings.bigItemHeight * 3
    height: presetsArea.height + (showPalette ? paletteBox.height : 0)
    color: UISettings.bgStrong
    border.color: UISettings.bgLight
    border.width: 2
    clip: true

    property bool showPalette: false
    property var dragTarget: null
    property int selectedFixture: -1
    property int selectedChannel: -1

    signal close()

    function loadPalette(pId)
    {
        var palette = paletteManager.getPalette(pId)
        if (palette)
        {
            dragTopBar.visible = false
            paletteToolbar.visible = true
            paletteToolbar.text = palette.name
            paletteBox.editPalette(palette)
            updatePresets(fixtureManager.shutterChannels)
        }
    }

    function updatePresets(presetModel)
    {
        selectedFixture = -1
        prList.model = null
        prList.model = presetModel
    }

    MouseArea
    {
        anchors.fill: parent
        onWheel: { return false }
    }

    Item
    {
        id: presetsArea
        width: parent.width
        height: UISettings.bigItemHeight * 3

        Rectangle
        {
            id: dragTopBar
            width: parent.width
            height: UISettings.listItemHeight
            z: 10
            gradient: Gradient
            {
                GradientStop { position: 0; color: UISettings.toolbarStartSub }
                GradientStop { position: 1; color: UISettings.toolbarEnd }
            }

            RobotoText
            {
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                label: qsTr("Shutter")
                fontSize: UISettings.textSizeDefault
                fontBold: true
            }
            MouseArea
            {
                anchors.fill: parent
                drag.target: toolRoot.dragTarget ? toolRoot.dragTarget : toolRoot
            }
            GenericButton
            {
                width: height
                height: parent.height
                anchors.right: parent.right
                border.color: UISettings.bgMedium
                useFontawesome: true
                label: FontAwesome.fa_xmark
                onClicked: toolRoot.close()
            }
        }

        EditorTopBar
        {
            id: paletteToolbar
            visible: false
            onBackClicked: toolRoot.parent.dismiss()
            onTextChanged: paletteBox.setName(text)
        }

        // fixture/channel selector tabs
        Rectangle
        {
            id: presetToolBar
            width: parent.width
            height: UISettings.iconSizeDefault
            y: dragTopBar.visible ? dragTopBar.height : paletteToolbar.height
            z: 10
            clip: true
            gradient: Gradient
            {
                GradientStop { position: 0; color: UISettings.toolbarStartSub }
                GradientStop { position: 1; color: UISettings.toolbarEnd }
            }

            ListView
            {
                id: prList
                anchors.fill: parent
                orientation: ListView.Horizontal
                boundsBehavior: Flickable.StopAtBounds

                delegate:
                    Rectangle
                    {
                        id: delegateRoot
                        width: UISettings.bigItemHeight * 1.3
                        height: presetToolBar.height
                        property bool isCurrentPreset: toolRoot.selectedFixture === fxID &&
                                                        toolRoot.selectedChannel === chIdx
                        color: isCurrentPreset ? UISettings.highlight :
                                (prMouseArea.pressed ? UISettings.bgLight : UISettings.bgMedium)
                        border.width: 1
                        border.color: isCurrentPreset ? UISettings.highlight : UISettings.bgLight

                        property int fxID: modelData.fixtureID
                        property int chIdx: modelData.channelIdx

                        Component.onCompleted:
                        {
                            if (toolRoot.selectedFixture === -1)
                            {
                                toolRoot.selectedFixture = fxID
                                toolRoot.selectedChannel = chIdx
                                capRepeater.model = fixtureManager.presetCapabilities(fxID, chIdx)
                                prFlickable.contentY = 0
                            }
                        }

                        RobotoText
                        {
                            x: 3
                            width: parent.width - 6
                            height: parent.height
                            label: modelData.name
                            fontSize: UISettings.textSizeDefault * 0.70
                            wrapText: true
                        }
                        MouseArea
                        {
                            id: prMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            drag.target: toolRoot.dragTarget ? toolRoot.dragTarget : toolRoot
                            drag.axis: Drag.XAndYAxis

                            onClicked:
                            {
                                toolRoot.selectedFixture = delegateRoot.fxID
                                toolRoot.selectedChannel = delegateRoot.chIdx
                                capRepeater.model = fixtureManager.presetCapabilities(toolRoot.selectedFixture, toolRoot.selectedChannel)
                                prFlickable.contentY = 0
                            }
                        }
                    }
            }
        }

        Flickable
        {
            id: prFlickable
            width: parent.width
            height: parent.height - presetToolBar.y - presetToolBar.height
            y: presetToolBar.y + presetToolBar.height
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: flowView.height

            Flow
            {
                id: flowView
                width: parent.width
                Repeater
                {
                    id: capRepeater
                    delegate: PresetCapabilityItem
                    {
                        capability: modelData
                        capIndex: index + 1
                        onValueChanged: function(value)
                        {
                            let pct = Math.round(value * 100 / 255)
                            paletteBox.updateValues(capability.preset, pct)
                            paletteBox.updatePreview()
                        }
                    }
                }
            }
        }
    }

    PaletteFanningBox
    {
        id: paletteBox
        visible: toolRoot.showPalette
        y: presetsArea.height
        width: parent.width
        paletteType: QLCPalette.Shutter
    }
}
