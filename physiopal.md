# PhysioPal - The Digital Physiotherapist  
**(Your recovery companion)**

---

## The Problem Statement
Physical therapy fails because of the **"Supervision Gap."**

A PT prescribes a routine, but the patient performs it at home:
- Unsupervised  
- Often with incorrect form  
- Risking further injury  

Key challenges:
- Continuous live monitoring is too expensive  
- Cloud-based AI cameras raise **serious privacy concerns**, especially for elderly patients  

---

## The Solution
**PhysioPal** is a **fully on-device digital physiotherapist**.

It:
- Uses **Apple Health** to assess physical readiness  
- Uses **ZeticAI’s Melange SDK** for real-time supervision  
- Runs with **zero latency**
- Keeps **all video data strictly offline**

---

## Demo Flow (Presentation Guide)

### Step 1: The Context Engine (Apple Health Integration)

**Scenario:**  
User opens the app to perform morning squats.

**Technology:**
- Queries `HKHealthStore` for:
  - `sleepAnalysis` (last night)
  - `activeEnergyBurned` (today)

**AI Decision:**
- Detects:
  - Only 4 hours of sleep  
  - Low energy levels  
- Adjusts routine:
  - From **15 deep squats → 10 assisted chair-squats**
- Goal: Prevent exhaustion-induced injury

**UX Detail:**
- Display recommendation in a **sloppy handwritten font**
- Feels like a doctor’s note rather than a machine output

---

### Step 2: The Supervision Engine (ZeticAI / Melange SDK)

**Scenario:**  
User sets up phone and begins exercises.

**Technology:**
- Runs **on-device pose estimation**
- Uses:
  - Zetic Melange SDK  
  - Google MediaPipe Pose Estimation  
  - Apple Neural Engine  

**Key Point to Emphasize:**
> “This camera feed never hits the internet.”

**Real-Time Feedback:**
- Tracks skeletal movement
- Detects incorrect posture (e.g., leaning forward)
- Provides instant correction guidance

---

### Step 3: The Handoff & Reward (Zoom + Gamification)

**Success Case:**
- User completes routine with proper form

**Reward:**
- Display **5 translucent alien hacker characters**
- They give a **fist bump animation**
- Keep them semi-transparent so:
  - Exercise summary remains readable

---

**Escalation Case:**
- If user repeatedly fails posture checks:

**System Response:**
- Transition from digital PT → real PT bridge

**Actions:**
- Instantly call physiotherapist (via **Twilio**, demo purpose)
- Enable:
  - Immediate human guidance  
  - Follow-up via **Zoom video call**
  - Automated Zoom API integration  

---

## Core Value Proposition

- ✅ Real-time supervision  
- ✅ Fully private (on-device AI)  
- ✅ Adaptive routines based on health data  
- ✅ Seamless escalation to human experts  
