# ai_phone

**AI Character Roleplay**: Interact with various AI personalities

## Getting Started

Setup local AI 

https://github.com/odrevet/odrevet/wiki/Local-AI


# AI Phone - Flutter Voice & Text Chat Application

A Flutter-based mobile application that simulates a phone interface for interacting with AI characters through voice calls and text messages.

## Features

### Voice Calls
- **Phone Menu Interface**: Native Android phone-like interface for making calls
- **Speech Recognition**: Uses Android's built-in speech-to-text module for voice input
- **Text-to-Speech**: Integrates with OpenAI-compatible TTS endpoints for realistic AI voice responses
- **Real-time Conversation**: voice conversations with AI characters

### SMS Messaging
- **Chat Interface**: Clean, modern SMS-style messaging interface
- **Typed Conversations**: Text-based interactions with AI characters
- **Message History**: Persistent conversation history for each contact
- **Real-time Responses**: Instant AI responses through API calls

### ontact Management
- **AI Character Cards**: Import and manage AI character cards
- **Contact List**: Organized list of available AI characters
- **Character Profiles**: Detailed character information including:
    - Name and description
    - Personality traits
    - Conversation scenarios
    - Custom avatars
    - Message examples

## Technical Stack

- **Framework**: Flutter
- **Platform**: Android (with built-in speech modules)
- **AI Integration**: OpenAI-compatible API endpoints
- **Speech**: Android native speech recognition
- **TTS**: OpenAI-compatible text-to-speech services

## Application Structure

### Core Views
1. **Phone View**: Voice call interface with speech recognition
2. **SMS View**: Text messaging interface
3. **Contact List**: Character management and selection

### AI Integration
- **Chat Completion API**: For generating AI responses
- **Text-to-Speech API**: For voice synthesis
- **Character Cards**: Support for importing AI character definitions

## Character Card Support

The application supports importing AI character cards in the contact list, allowing users to:
- Load pre-defined AI personalities
- Customize character traits and behaviors
- Set conversation contexts and scenarios
- Import character avatars and descriptions

## Setup

### Dependencies

- OpenAI-compatible API endpoint access
- Device with microphone and speakers

### API Configuration
Configure your open API or complatible endpoints for:
- Chat completion services
- Text-to-speech services
- Any authentication tokens required
 
## Usage

### Making Voice Calls
1. Select a contact from the contact list
2. Tap the phone icon to initiate a call
3. Speak naturally - the app will transcribe your voice
4. Listen to AI responses through text-to-speech

### Sending SMS Messages
1. Select a contact from the contact list
2. Tap the SMS icon to open messaging
3. Type your messages and receive AI responses
4. View conversation history

### Managing Contacts
1. Access the contact list
2. Import AI character cards
3. Customize character profiles
4. Organize your AI contacts

# Character card debug 

png metadata can be inspected using bash 

```sh
b64=$(identify -verbose "$1" | awk '/chara: /{flag=1; print substr($0, index($0,$2)); next} /^  [a-zA-Z_]/ {flag=0} flag {print}' | tr -d '\n')
echo "$b64" | base64 -d
```

