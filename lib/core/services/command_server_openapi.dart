// GENERATED FILE - DO NOT EDIT MANUALLY
// Run `dart run scripts/generate_openapi.dart` to update

part of 'command_server.dart';

const String _openApiYaml = r"""
openapi: 3.0.0
info:
  title: App Screenshots API
  description: Local API for controlling the App Screenshots editor.
  version: 1.0.0
servers:
  - url: /
components:
  schemas:
    SuccessResponse:
      type: object
      properties:
        ok:
          type: boolean
          example: true
        data:
          type: object
    ErrorResponse:
      type: object
      properties:
        ok:
          type: boolean
          example: false
        error:
          type: string
          example: "Invalid parameter"
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: LocalSessionToken
security:
  - bearerAuth: []
paths:
  /api/editor/state:
    post:
      tags:
        - Editor
      summary: Execute state
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-background:
    post:
      tags:
        - Editor
      summary: Execute set-background
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - color
              properties:
                color:
                  type: string
                  example: "#FF5733"
                  description: Hex color code
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-gradient:
    post:
      tags:
        - Editor
      summary: Execute set-gradient
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-mesh-gradient:
    post:
      tags:
        - Editor
      summary: Execute set-mesh-gradient
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                mesh:
                  type: object
                  description: JSON representing mesh gradient points
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-transparent:
    post:
      tags:
        - Editor
      summary: Execute set-transparent
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-frame:
    post:
      tags:
        - Editor
      summary: Execute set-frame
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - device
              properties:
                device:
                  type: string
                  example: "iPhone 16 Pro"
                  description: Device name string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/list-devices:
    post:
      tags:
        - Editor
      summary: Execute list-devices
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/list-fonts:
    post:
      tags:
        - Editor
      summary: Execute list-fonts
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/list-icons:
    post:
      tags:
        - Editor
      summary: Execute list-icons
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-padding:
    post:
      tags:
        - Editor
      summary: Execute set-padding
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - padding
              properties:
                padding:
                  type: number
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-corner-radius:
    post:
      tags:
        - Editor
      summary: Execute set-corner-radius
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - radius
              properties:
                radius:
                  type: number
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-rotation:
    post:
      tags:
        - Editor
      summary: Execute set-rotation
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                x:
                  type: number
                y:
                  type: number
                z:
                  type: number
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-orientation:
    post:
      tags:
        - Editor
      summary: Execute set-orientation
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-image:
    post:
      tags:
        - Editor
      summary: Execute set-image
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - file
              properties:
                file:
                  type: string
                  example: "/path/to/image.png"
                  description: Absolute path to image
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-image-position:
    post:
      tags:
        - Editor
      summary: Execute set-image-position
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-image-base64:
    post:
      tags:
        - Editor
      summary: Execute set-image-base64
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-display-type:
    post:
      tags:
        - Editor
      summary: Execute set-display-type
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-doodle:
    post:
      tags:
        - Editor
      summary: Execute set-doodle
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - enabled
              properties:
                enabled:
                  type: boolean
                iconSource:
                  type: integer
                  description: 0=sf, 1=material, 2=emoji
                iconSize:
                  type: number
                spacing:
                  type: number
                iconOpacity:
                  type: number
                rotation:
                  type: number
                iconColor:
                  type: integer
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/set-grid:
    post:
      tags:
        - Editor
      summary: Execute set-grid
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/add-text:
    post:
      tags:
        - Editor
      summary: Execute add-text
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - text
                - fontSize
              properties:
                text:
                  type: string
                  example: "Hello World"
                fontSize:
                  type: number
                  example: 40
                font:
                  type: string
                  example: "Inter"
                color:
                  type: string
                  example: "#FFFFFF"
                x:
                  type: number
                y:
                  type: number
                width:
                  type: number
                align:
                  type: string
                  enum: [left, center, right]
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/update-text:
    post:
      tags:
        - Editor
      summary: Execute update-text
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - id
              properties:
                id:
                  type: string
                  description: Overlay ID
                text:
                  type: string
                fontSize:
                  type: number
                font:
                  type: string
                color:
                  type: string
                x:
                  type: number
                y:
                  type: number
                width:
                  type: number
                align:
                  type: string
                scale:
                  type: number
                rotation:
                  type: number
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/add-image:
    post:
      tags:
        - Editor
      summary: Execute add-image
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - file
              properties:
                file:
                  type: string
                  description: Absolute path to image
                x:
                  type: number
                y:
                  type: number
                width:
                  type: number
                height:
                  type: number
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/update-image:
    post:
      tags:
        - Editor
      summary: Execute update-image
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/add-icon:
    post:
      tags:
        - Editor
      summary: Execute add-icon
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/update-icon:
    post:
      tags:
        - Editor
      summary: Execute update-icon
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/add-magnifier:
    post:
      tags:
        - Editor
      summary: Execute add-magnifier
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/update-magnifier:
    post:
      tags:
        - Editor
      summary: Execute update-magnifier
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/select-overlay:
    post:
      tags:
        - Editor
      summary: Execute select-overlay
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/delete-overlay:
    post:
      tags:
        - Editor
      summary: Execute delete-overlay
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/move-overlay:
    post:
      tags:
        - Editor
      summary: Execute move-overlay
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/copy-overlay:
    post:
      tags:
        - Editor
      summary: Execute copy-overlay
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/paste-overlay:
    post:
      tags:
        - Editor
      summary: Execute paste-overlay
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/bring-forward:
    post:
      tags:
        - Editor
      summary: Execute bring-forward
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/send-backward:
    post:
      tags:
        - Editor
      summary: Execute send-backward
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/list-overlays:
    post:
      tags:
        - Editor
      summary: Execute list-overlays
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/apply-preset:
    post:
      tags:
        - Editor
      summary: Execute apply-preset
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/undo:
    post:
      tags:
        - Editor
      summary: Execute undo
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/redo:
    post:
      tags:
        - Editor
      summary: Execute redo
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/save-design:
    post:
      tags:
        - Editor
      summary: Execute save-design
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/load-design:
    post:
      tags:
        - Editor
      summary: Execute load-design
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/export:
    post:
      tags:
        - Editor
      summary: Execute export
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                path:
                  type: string
                  description: Output file path (optional)
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/editor/export-all:
    post:
      tags:
        - Editor
      summary: Execute export-all
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/list:
    post:
      tags:
        - Library
      summary: Execute list
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/folders:
    post:
      tags:
        - Library
      summary: Execute folders
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/get:
    post:
      tags:
        - Library
      summary: Execute get
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/delete:
    post:
      tags:
        - Library
      summary: Execute delete
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/rename:
    post:
      tags:
        - Library
      summary: Execute rename
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/search:
    post:
      tags:
        - Library
      summary: Execute search
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/create-folder:
    post:
      tags:
        - Library
      summary: Execute create-folder
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/delete-folder:
    post:
      tags:
        - Library
      summary: Execute delete-folder
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/move:
    post:
      tags:
        - Library
      summary: Execute move
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/import:
    post:
      tags:
        - Library
      summary: Execute import
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/library/export:
    post:
      tags:
        - Library
      summary: Execute export
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/open:
    post:
      tags:
        - Board
      summary: Execute open
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                displayType:
                  type: string
                  example: "APP_IPHONE_67"
                zoneCount:
                  type: integer
                  example: 3
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/state:
    post:
      tags:
        - Board
      summary: Execute state
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/add-zone:
    post:
      tags:
        - Board
      summary: Execute add-zone
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                displayType:
                  type: string
                  example: "APP_IPHONE_69"
                orientation:
                  type: string
                  example: "portrait"
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/remove-zone:
    post:
      tags:
        - Board
      summary: Execute remove-zone
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                index:
                  type: integer
                  example: 0
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/update-zone:
    post:
      tags:
        - Board
      summary: Execute update-zone
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                index:
                  type: integer
                  example: 0
                displayType:
                  type: string
                orientation:
                  type: string
                name:
                  type: string
                included:
                  type: boolean
                  example: true
                locked:
                  type: boolean
                  example: true
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/set-zone-spacing:
    post:
      tags:
        - Board
      summary: Execute set-zone-spacing
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                gap:
                  type: number
                  example: 0
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/arrange-zones:
    post:
      tags:
        - Board
      summary: Execute arrange-zones
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                gap:
                  type: number
                  example: 120
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/list-templates:
    post:
      tags:
        - Board
      summary: Execute list-templates
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/apply-template:
    post:
      tags:
        - Board
      summary: Execute apply-template
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                  example: "tilted_trio"
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/add-frame:
    post:
      tags:
        - Board
      summary: Execute add-frame
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                zoneId:
                  type: string
                imagePath:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/remove-frame:
    post:
      tags:
        - Board
      summary: Execute remove-frame
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/update-frame:
    post:
      tags:
        - Board
      summary: Execute update-frame
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                x:
                  type: number
                y:
                  type: number
                width:
                  type: number
                height:
                  type: number
                rotationDegrees:
                  type: number
                  example: -8
                zIndex:
                  type: integer
                  example: 0
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/set-frame-image:
    post:
      tags:
        - Board
      summary: Execute set-frame-image
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                path:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/import-images:
    post:
      tags:
        - Board
      summary: Execute import-images
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                paths:
                  type: array
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/export:
    post:
      tags:
        - Board
      summary: Execute export
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                zoneId:
                  type: string
                outputDir:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/export-all:
    post:
      tags:
        - Board
      summary: Execute export-all
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                outputDir:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/board/save-design:
    post:
      tags:
        - Board
      summary: Execute save-design
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                name:
                  type: string
                override:
                  type: boolean
                  example: false
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/open:
    post:
      tags:
        - Multi
      summary: Execute open
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/state:
    post:
      tags:
        - Multi
      summary: Execute state
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/switch-design:
    post:
      tags:
        - Multi
      summary: Execute switch-design
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/add-design:
    post:
      tags:
        - Multi
      summary: Execute add-design
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - displayType
              properties:
                displayType:
                  type: string
                  example: "APP_IPHONE_69"
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/remove-design:
    post:
      tags:
        - Multi
      summary: Execute remove-design
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/duplicate-design:
    post:
      tags:
        - Multi
      summary: Execute duplicate-design
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/reorder:
    post:
      tags:
        - Multi
      summary: Execute reorder
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/apply-preset:
    post:
      tags:
        - Multi
      summary: Execute apply-preset
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/batch:
    post:
      tags:
        - Multi
      summary: Execute batch
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - action
              properties:
                action:
                  type: string
                  example: "set-background"
                value:
                  type: string
                color:
                  type: string
                file:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/set-image:
    post:
      tags:
        - Multi
      summary: Execute set-image
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/multi/save-design:
    post:
      tags:
        - Multi
      summary: Execute save-design
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/state:
    post:
      tags:
        - Translate
      summary: Execute state
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/get-texts:
    post:
      tags:
        - Translate
      summary: Execute get-texts
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/all:
    post:
      tags:
        - Translate
      summary: Execute all
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/preview:
    post:
      tags:
        - Translate
      summary: Execute preview
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/edit:
    post:
      tags:
        - Translate
      summary: Execute edit
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/apply-manual:
    post:
      tags:
        - Translate
      summary: Execute apply-manual
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - locale
                - translations
              properties:
                locale:
                  type: string
                  example: "es"
                translations:
                  type: object
                  additionalProperties: true
                  description: Map of overlayId to text
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/remove-locale:
    post:
      tags:
        - Translate
      summary: Execute remove-locale
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/set-prompt:
    post:
      tags:
        - Translate
      summary: Execute set-prompt
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/override-overlay:
    post:
      tags:
        - Translate
      summary: Execute override-overlay
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - locale
                - overlayId
              properties:
                locale:
                  type: string
                overlayId:
                  type: string
                fontSize:
                  type: number
                font:
                  type: string
                color:
                  type: string
                x:
                  type: number
                y:
                  type: number
                width:
                  type: number
                scale:
                  type: number
                rotation:
                  type: number
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/translate/set-locale-image:
    post:
      tags:
        - Translate
      summary: Execute set-locale-image
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - locale
                - data
              properties:
                locale:
                  type: string
                data:
                  type: string
                  description: Base64-encoded image bytes
                slot:
                  type: integer
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/preset/list:
    post:
      tags:
        - Preset
      summary: Execute list
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/preset/show:
    post:
      tags:
        - Preset
      summary: Execute show
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/asc/apps:
    post:
      tags:
        - App Store Connect
      summary: Execute apps
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/asc/custom-product-pages:
    post:
      tags:
        - App Store Connect
      summary: Execute custom-product-pages
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - appId
              properties:
                appId:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/asc/upload:
    post:
      tags:
        - App Store Connect
      summary: Execute upload
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - appId
                - displayType
              properties:
                appId:
                  type: string
                sourceDirectory:
                  type: string
                screenshots:
                  type: object
                  description: Map of locale to base64 image objects
                displayType:
                  type: string
                platform:
                  type: string
                customProductPageId:
                  type: string
                locales:
                  type: array
                deleteExisting:
                  type: boolean
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/play/upload:
    post:
      tags:
        - Google Play
      summary: Execute upload
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - packageName
                - imageType
              properties:
                packageName:
                  type: string
                sourceDirectory:
                  type: string
                screenshots:
                  type: object
                  description: Map of locale to base64 image objects
                imageType:
                  type: string
                locales:
                  type: array
                deleteExisting:
                  type: boolean
                changesNotSentForReview:
                  type: boolean
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/collaboration/share:
    post:
      tags:
        - Collaboration
      summary: Execute share
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - file
              properties:
                file:
                  type: string
                fileName:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/collaboration/save:
    post:
      tags:
        - Collaboration
      summary: Execute save
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - localPath
                - workingPath
              properties:
                localPath:
                  type: string
                workingPath:
                  type: string
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/jobs/list:
    post:
      tags:
        - Jobs
      summary: Execute list
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/jobs/status:
    post:
      tags:
        - Jobs
      summary: Execute status
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/status:
    get:
      tags:
        - Server
      summary: Get server status
      responses:
        "200":
          description: Successful execution
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SuccessResponse"
  /api/capabilities:
    get:
      tags:
        - Server
      summary: Get supported integrations and credential state
      responses:
        "200":
          description: Successful execution
""";

const String _swaggerUiHtml = r"""
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>App Screenshots API Docs</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />
  <style>
    body { margin: 0; padding: 0; }
    .swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
<div id="swagger-ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"></script>
<script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js"></script>
<script>
window.onload = () => {
  window.ui = SwaggerUIBundle({
    url: '/api/docs/openapi.yaml',
    requestInterceptor: (request) => {
      request.headers['Authorization'] = 'Bearer __APPSHOTS_TOKEN__';
      return request;
    },
    dom_id: '#swagger-ui',
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    layout: "StandaloneLayout"
  });
};
</script>
</body>
</html>
""";
