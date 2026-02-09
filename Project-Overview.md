# Yatra Sathi - Project Documentation

## 📋 Project Overview

**Yatra Sathi** (यात्रा साथी) is a modern ride-sharing web application designed specifically for Nepal. The platform connects vehicle owners with travelers, allowing users to post ride offers, search for available rides, make seat reservations, and communicate in real-time through an integrated chat system.

> **"Your Trusted Travel Companion"** 🇳🇵

---

## 🎯 Nature of the Project

| Attribute | Details |
|-----------|---------|
| **Type** | Full-stack Web Application |
| **Domain** | Ride-sharing / Carpooling Platform |
| **Target Market** | Nepal (Nepal-specific features) |
| **Architecture** | Client-Server with Real-time Communication |
| **Deployment** | Containerized with Docker |

### Core Functionalities
1. **User Management** - Registration, authentication, profile management with photo upload
2. **Ride Offers** - Vehicle owners can post ride offers with details (route, timing, fare, vehicle info)
3. **Search & Discovery** - Passengers can search/filter rides by route, date, vehicle type, and price
4. **Seat Reservation** - Real-time seat booking system with availability tracking
5. **Real-time Chat** - Socket.io powered messaging between riders for coordination
6. **Auto-cleanup** - Automated removal of expired ride offers via cron jobs

---

## 🏗️ Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         React 18 (Vite)                              │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │   │
│  │  │   Pages     │  │ Components  │  │   Context   │  │  Services  │ │   │
│  │  │  (Views)    │  │   (UI)      │  │  (State)    │  │  (API/WS)  │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │   │
│  │                                                                      │   │
│  │  Tech: React Router, Axios, Socket.io-client, Tailwind CSS           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼ HTTP / WebSocket
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SERVER LAYER (Node.js)                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Express.js + Socket.io                          │   │
│  │                                                                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │   │
│  │  │   Routes    │  │ Controllers │  │ Middleware  │  │   Models   │ │   │
│  │  │  (API)      │  │ (Business)  │  │ (Auth/Error)│  │ (Mongoose) │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │   │
│  │                                                                      │   │
│  │  Services: Cleanup (node-cron), Cloudinary (Images)                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER                                         │
│  ┌─────────────────────┐    ┌─────────────────────────────────────────┐   │
│  │     MongoDB         │    │         Cloudinary                      │   │
│  │  (Primary Database) │    │    (Image Storage - Photos/Vehicles)    │   │
│  └─────────────────────┘    └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Backend (MERN Stack)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Node.js** | 18+ | Runtime environment |
| **Express.js** | ^4.18.2 | Web framework |
| **MongoDB** | 8.0+ | NoSQL database |
| **Mongoose** | ^8.0.0 | ODM for MongoDB |
| **Socket.io** | ^4.6.0 | Real-time bi-directional communication |
| **JWT** | ^9.0.2 | Authentication tokens |
| **bcryptjs** | ^2.4.3 | Password hashing |
| **Cloudinary** | ^1.41.0 | Image storage & management |
| **Multer** | ^1.4.5 | File upload handling |
| **Helmet** | ^7.1.0 | Security headers |
| **express-rate-limit** | ^7.1.5 | API rate limiting |
| **express-validator** | ^7.0.1 | Input validation |
| **node-cron** | ^3.0.3 | Scheduled tasks (cleanup) |
| **CORS** | ^2.8.5 | Cross-origin resource sharing |

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **React** | ^18.2.0 | UI library |
| **Vite** | ^5.0.8 | Build tool & dev server |
| **React Router DOM** | ^6.20.0 | Client-side routing |
| **Axios** | ^1.6.2 | HTTP client |
| **Socket.io-client** | ^4.6.0 | Real-time communication |
| **Tailwind CSS** | ^3.3.6 | Utility-first CSS framework |
| **react-hook-form** | ^7.49.2 | Form management |
| **Yup** | ^1.3.3 | Form validation schema |
| **@hookform/resolvers** | ^3.3.2 | Form validation integration |
| **react-datepicker** | ^4.21.0 | Date/time picker |
| **lucide-react** | ^0.294.0 | Icon library |
| **react-hot-toast** | ^2.4.1 | Toast notifications |

### DevOps & Infrastructure

| Technology | Purpose |
|------------|---------|
| **Docker** | Containerization |
| **Docker Compose** | Multi-container orchestration |
| **Nginx** | Reverse proxy & static file serving |
| **Certbot** | SSL/TLS certificate management |

---

## 📁 Project Structure

```
Yatra-Sathi/
├── backend/                          # Node.js Express Backend
│   ├── config/                       # Configuration files
│   │   ├── db.js                     # MongoDB connection setup
│   │   └── cloudinary.js             # Cloudinary configuration
│   │
│   ├── controllers/                  # Business logic controllers
│   │   ├── authController.js         # Authentication (register/login)
│   │   ├── offerController.js        # Ride offers CRUD
│   │   ├── reservationController.js  # Seat reservations
│   │   └── chatController.js         # Chat history & conversations
│   │
│   ├── middleware/                   # Express middleware
│   │   ├── auth.js                   # JWT authentication middleware
│   │   ├── errorHandler.js           # Global error handling
│   │   └── upload.js                 # File upload (Multer + Cloudinary)
│   │
│   ├── models/                       # Mongoose schemas
│   │   ├── User.js                   # User model
│   │   ├── VehicleOffer.js           # Ride offer model
│   │   ├── Reservation.js            # Reservation model
│   │   └── ChatMessage.js            # Chat message model
│   │
│   ├── routes/                       # API route definitions
│   │   ├── auth.js                   # Auth routes (/api/auth)
│   │   ├── offers.js                 # Offer routes (/api/offers)
│   │   ├── reservations.js           # Reservation routes (/api/reservations)
│   │   └── chat.js                   # Chat routes (/api/chat)
│   │
│   ├── utils/                        # Utility functions
│   │   ├── validators.js             # Input validation schemas
│   │   └── cleanupService.js         # Expired offers cleanup (cron)
│   │
│   ├── server.js                     # Main entry point
│   ├── package.json                  # Dependencies
│   ├── .env.example                  # Environment variables template
│   ├── .env                          # Environment variables (local)
│   ├── Dockerfile                    # Container definition
│   └── .dockerignore                 # Docker ignore rules
│
├── frontend/                         # React Frontend
│   ├── src/
│   │   ├── components/               # Reusable UI components
│   │   │   ├── Navbar.jsx            # Navigation bar
│   │   │   ├── Footer.jsx            # Footer component
│   │   │   ├── OfferCard.jsx         # Ride offer card
│   │   │   ├── SearchBar.jsx         # Search/filter component
│   │   │   ├── LoadingSpinner.jsx    # Loading indicator
│   │   │   └── ProtectedRoute.jsx    # Auth route guard
│   │   │
│   │   ├── context/                  # React context
│   │   │   └── AuthContext.jsx       # Authentication context
│   │   │
│   │   ├── pages/                    # Page components
│   │   │   ├── Home.jsx              # Landing page
│   │   │   ├── Login.jsx             # Login page
│   │   │   ├── Register.jsx          # Registration page
│   │   │   ├── Dashboard.jsx         # User dashboard
│   │   │   ├── Offers.jsx            # Browse offers page
│   │   │   ├── OfferDetail.jsx       # Offer details page
│   │   │   ├── PostOffer.jsx         # Create offer page
│   │   │   ├── Profile.jsx           # User profile page
│   │   │   ├── Chat.jsx              # Chat interface
│   │   │   └── ChatList.jsx          # Conversations list
│   │   │
│   │   ├── services/                 # API & Socket services
│   │   │   ├── api.js                # Axios HTTP client
│   │   │   └── socket.js             # Socket.io client
│   │   │
│   │   ├── utils/                    # Helper functions
│   │   │   └── formatters.js         # Data formatters (date, currency)
│   │   │
│   │   ├── App.jsx                   # Main app component
│   │   ├── main.jsx                  # Entry point
│   │   └── index.css                 # Global styles
│   │
│   ├── index.html                    # HTML template
│   ├── package.json                  # Dependencies
│   ├── vite.config.js                # Vite configuration
│   ├── tailwind.config.js            # Tailwind CSS config
│   ├── postcss.config.js             # PostCSS config
│   └── .env.example                  # Environment variables template
│
├── docker-compose.yml                # Docker orchestration
├── nginx.conf                        # Nginx configuration (production)
├── README.md                         # Project documentation
└── LICENSE                           # MIT License
```

---

## 🔌 API Endpoints

### Authentication (`/api/auth`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/register` | Register new user with photo | No |
| POST | `/login` | User login | No |
| GET | `/me` | Get current user profile | Yes |
| PUT | `/profile` | Update profile | Yes |
| PUT | `/password` | Change password | Yes |

### Ride Offers (`/api/offers`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/` | List all offers (filterable) | No |
| GET | `/:id` | Get single offer details | No |
| POST | `/` | Create new offer | Yes |
| PUT | `/:id` | Update offer | Yes (Owner) |
| DELETE | `/:id` | Delete offer | Yes (Owner) |

### Reservations (`/api/reservations`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/` | Book seats | Yes |
| GET | `/` | Get my reservations | Yes |
| PUT | `/:id/cancel` | Cancel reservation | Yes |

### Chat (`/api/chat`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/:offerId` | Get chat history for offer | Yes |
| GET | `/conversations` | Get my conversations | Yes |

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Server health status |

---

## ⚡ Socket.io Events (Real-time)

### Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `join-chat` | `{ offerId }` | Join chat room for an offer |
| `leave-chat` | `{ offerId }` | Leave chat room |
| `send-message` | `{ offerId, receiverId, message }` | Send a message |
| `typing` | `{ offerId }` | Typing indicator started |
| `stop-typing` | `{ offerId }` | Typing indicator stopped |

### Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `new-message` | `ChatMessage` | New message received |
| `user-joined` | `{ userId, name }` | User joined chat |
| `user-typing` | `{ userId, name }` | User is typing |
| `user-stop-typing` | `{ userId }` | User stopped typing |
| `message-notification` | `{ offerId, sender, preview }` | New message notification |
| `error` | `{ message }` | Error message |

---

## 🗄️ Database Schema (MongoDB)

### User Collection
```javascript
{
  _id: ObjectId,
  name: String (required, 2-50 chars),
  gender: Enum ['male', 'female', 'other'],
  email: String (required, unique),
  phone: String (required, unique, Nepal format: +9779XXXXXXXX),
  password: String (hashed, min 6 chars),
  photo: String (Cloudinary URL),
  photoPublicId: String,
  verified: Boolean (default: false),
  createdAt: Date,
  updatedAt: Date
}
```

### VehicleOffer Collection
```javascript
{
  _id: ObjectId,
  ownerId: ObjectId (ref: User),
  vehicleType: Enum ['Car', 'Jeep', 'Van', 'Motorcycle', 'Micro Bus', 'Bus'],
  vehicleNumber: String (Nepal format),
  vehiclePhoto: String (Cloudinary URL),
  vehiclePhotoPublicId: String,
  seatPhoto: String (optional, Cloudinary URL),
  seatPhotoPublicId: String,
  seatsTotal: Number (1-50),
  seatsAvailable: Number,
  fare: Number (NPR),
  fromLocation: String,
  toLocation: String,
  leaveTime: Date,
  reachTime: Date,
  description: String (max 500 chars),
  contactNumber: String (Nepal format),
  status: Enum ['active', 'expired', 'cancelled'],
  expiresAt: Date (auto: leaveTime + 24h),
  createdAt: Date
}
```

### Reservation Collection
```javascript
{
  _id: ObjectId,
  offerId: ObjectId (ref: VehicleOffer),
  userId: ObjectId (ref: User),
  seatsReserved: Number (min 1),
  status: Enum ['confirmed', 'cancelled'],
  createdAt: Date
}
```

### ChatMessage Collection
```javascript
{
  _id: ObjectId,
  offerId: ObjectId (ref: VehicleOffer),
  senderId: ObjectId (ref: User),
  receiverId: ObjectId (ref: User),
  message: String (max 1000 chars),
  read: Boolean (default: false),
  timestamp: Date
}
```

---

## 🔒 Security Features

1. **Authentication**
   - JWT-based stateless authentication
   - Password hashing with bcrypt (10 salt rounds)
   - Token expiration (configurable)

2. **Authorization**
   - Protected routes middleware
   - Resource ownership verification
   - Socket.io JWT authentication

3. **Input Validation**
   - express-validator for request validation
   - Schema validation with Yup (frontend)
   - File upload restrictions (Multer)

4. **API Security**
   - Rate limiting (100 req/15min general, 10 req/15min auth)
   - Helmet.js for security headers
   - CORS configuration
   - MongoDB injection prevention (Mongoose)

5. **Data Protection**
   - Environment variables for secrets
   - Cloudinary for secure image storage
   - Password excluded from queries by default

---

## 🇳🇵 Nepal-Specific Features

| Feature | Implementation |
|---------|----------------|
| **Phone Validation** | Regex pattern: `^(\+977)?[9][6-9]\d{8}$` |
| **Currency** | NPR (Nepali Rupees) formatting |
| **Vehicle Numbers** | Nepal format: BA 1 KHA 1234 |
| **Theme Colors** | Nepal flag colors (blue/crimson) |
| **Vehicle Types** | Car, Jeep, Van, Motorcycle, Micro Bus, Bus |

---

## 🚀 Deployment Architecture

### Docker Compose Setup

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Network                           │
│                    (yatra-network)                          │
│                                                              │
│  ┌─────────────────────┐      ┌─────────────────────────┐  │
│  │  yatra-api          │      │      yatra-nginx        │  │
│  │  (Node.js Backend)  │◄────►│   (Reverse Proxy)       │  │
│  │  Port: 5000         │      │   Ports: 80, 443        │  │
│  └─────────────────────┘      └─────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Services

1. **yatra-backend**
   - Node.js application container
   - Port: 5000
   - Environment: Production
   - Health check enabled

2. **nginx**
   - Reverse proxy
   - Serves static frontend (built React app)
   - SSL/TLS termination
   - Auto-reload every 6 hours

### Environment Variables

**Backend (.env)**
```
PORT=5000
NODE_ENV=development/production
MONGODB_URI=mongodb://localhost:27017/yatrasathi
JWT_SECRET=your-secret-key
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
FRONTEND_URL=http://localhost:5173
```

**Frontend (.env)**
```
VITE_API_URL=http://localhost:5000/api
VITE_SOCKET_URL=http://localhost:5000
```

---

## 📊 Key Features Summary

| Feature | Status | Technology |
|---------|--------|------------|
| User Registration | ✅ | JWT, Multer, Cloudinary |
| User Login | ✅ | JWT, bcrypt |
| Profile Management | ✅ | Cloudinary photo upload |
| Post Ride Offers | ✅ | Mongoose, validation |
| Search/Filter Offers | ✅ | MongoDB queries |
| Seat Reservation | ✅ | Transaction-like updates |
| Real-time Chat | ✅ | Socket.io |
| Auto-cleanup | ✅ | node-cron |
| Responsive Design | ✅ | Tailwind CSS |
| Docker Deployment | ✅ | Docker Compose |

---

## 🧪 Development Commands

### Backend
```bash
cd backend
npm install
npm run dev    # Development with nodemon
npm start      # Production
```

### Frontend
```bash
cd frontend
npm install
npm run dev     # Development server
npm run build   # Production build
npm run preview # Preview production build
```

### Docker
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

---

## 📈 Future Enhancements (Potential)

1. **Mobile App** - React Native or Flutter
2. **Payment Integration** - eSewa, Khalti (Nepal wallets)
3. **Location Tracking** - GPS integration
4. **Rating System** - Driver/passenger ratings
5. **Push Notifications** - Firebase Cloud Messaging
6. **Admin Dashboard** - Analytics & moderation
7. **SMS Notifications** - Twilio integration
8. **Multi-language** - Nepali language support

---

## 📝 License

**MIT License** - Feel free to use for your own projects!

---

## 👥 Target Users

- **Vehicle Owners** - People with vehicles looking to share rides and earn money
- **Travelers/Passengers** - People looking for affordable transportation options
- **Daily Commuters** - Regular travelers on common routes

---

## 🎨 Design Philosophy

- **Mobile-first** responsive design
- **Nepal-themed** color palette (blue/crimson)
- **Glassmorphism** UI effects
- **Real-time** updates for dynamic feel
- **Simple & Intuitive** user experience

---

*Document generated on: 2026-02-09*
*Project location: /Users/kalikali/Documents/Backend/Yatra-Sathi*
