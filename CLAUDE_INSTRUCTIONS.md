# Claude Development Instructions - TIM3 Project

**🚨 CRITICAL: Read this file FIRST before doing any work on TIM3**

## 📋 **Mandatory Documentation Updates**

**EVERY TIME you work on TIM3, you MUST update these files:**

### **1. ALWAYS UPDATE AFTER EACH WORK SESSION**
```bash
# Primary status files (UPDATE EVERY SESSION)
apps/tim3/STATUS.md                    # Current status snapshot
apps/tim3/IMPLEMENTATION_LOG.md        # Progress history with details

# Git workflow (UPDATE IF PROCESS CHANGES)  
apps/tim3/GIT_WORKFLOW.md             # Commit guidance for user
```

### **2. ALWAYS UPDATE AFTER MAJOR MILESTONES**
```bash
# Planning docs (UPDATE WHEN PHASES COMPLETE)
plan/development/README.md             # Development strategy progress
plan/roadmap/README.md                 # Roadmap vs actual progress
plan/CLAUDE_HANDOFF.md                # Original plan (mark items complete)

# Architecture docs (UPDATE WHEN ARCHITECTURE CHANGES)
plan/architecture/README.md           # If architectural changes made
plan/specs/README.md                  # If technical specs change
```

## 🎯 **Update Protocol**

### **At Start of Each Session**
1. **Read STATUS.md first** - understand current state
2. **Read IMPLEMENTATION_LOG.md** - understand what's been done
3. **Check git log** - see recent progress
4. **Plan work based on "Next Steps" in STATUS.md**

### **During Work Session**
- Focus on building/coding
- Take notes on progress for documentation updates

### **At End of Each Session** 
1. **Update STATUS.md** with:
   - New progress made
   - Current status of all components  
   - Next steps for future sessions
   - Any blockers or issues

2. **Update IMPLEMENTATION_LOG.md** with:
   - Detailed description of work completed
   - Technical achievements
   - Test results
   - Architecture decisions made

3. **Update planning docs** if major milestones completed

4. **Recommend git commit** with updated docs

## 📁 **Documentation File Purposes**

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `STATUS.md` | Current snapshot | Every session |
| `IMPLEMENTATION_LOG.md` | Detailed history | Every session |
| `GIT_WORKFLOW.md` | Git guidance | When process changes |
| `plan/development/README.md` | Dev strategy progress | Major milestones |
| `plan/roadmap/README.md` | Timeline vs reality | Major milestones |
| `plan/CLAUDE_HANDOFF.md` | Original requirements | Mark items complete |

## 🎪 **Context Continuity System**

### **For User Confidence**
The user should NEVER worry about losing context between Claude sessions because:

1. **STATUS.md** = Instant context restoration
2. **IMPLEMENTATION_LOG.md** = Complete development history  
3. **Git commits** = Permanent progress record
4. **Planning docs** = Requirements + progress tracking

### **For New Claude Sessions**
Any new Claude can immediately understand:
- What's been built (STATUS.md)
- How we got here (IMPLEMENTATION_LOG.md)  
- What's next (Next Steps sections)
- Original plan (CLAUDE_HANDOFF.md)
- Architecture decisions (various planning docs)

## 🚨 **CRITICAL RULES**

### **Documentation Rules (NEVER SKIP)**
1. **Always read STATUS.md first** before starting work
2. **Always update STATUS.md and IMPLEMENTATION_LOG.md** before ending session
3. **Always include documentation updates in git commits**
4. **Always explain to user what documentation was updated**

### **Git Commit Rules**
```bash
# ALWAYS include doc updates in commits
git add apps/tim3/ plan/

# ALWAYS use comprehensive commit messages
git commit -m "feat: [what was built]

[technical details]
📚 Documentation updated: STATUS.md, IMPLEMENTATION_LOG.md
🤖 Generated with Claude Code"
```

### **Communication Rules**
- **Tell user what docs were updated** after each session
- **Recommend git commits** with proper messages
- **Explain context preservation** when relevant

## 🎯 **Current Project Status Context**

### **Architecture Implemented**
- 5-process system: Coordinator + Lock + Token + State + Mock-USDA
- Professional testing framework with Busted + Mock AO
- Custom Node.js build system (Docker-free)
- Comprehensive documentation system

### **What's Complete**
- ✅ Project foundation and architecture
- ✅ Development environment (Homebrew + Lua + testing)
- ✅ Mock USDA token (8 passing tests)
- ✅ Build and testing pipeline

### **What's Next**
- 🟡 TIM3 Coordinator Process (main user interaction handler)
- ⭕ State Manager Process 
- ⭕ Lock Manager Process
- ⭕ Token Manager Process
- ⭕ Frontend React application

### **User Context**
- User is non-developer but technically literate
- User wants clear explanations and options
- User values security and proper architecture
- User commits regularly to GitHub for safety

## 💡 **Success Pattern**

**Every Claude session should follow this pattern:**

1. **Read** → STATUS.md + IMPLEMENTATION_LOG.md
2. **Plan** → What to build based on "Next Steps"  
3. **Build** → Focus on coding with explanations
4. **Document** → Update STATUS.md + IMPLEMENTATION_LOG.md
5. **Commit** → Recommend git commit with docs
6. **Context** → Ensure user knows session is preserved

This creates an unbreakable chain of context and progress! 🔗

---

**🎯 Ready to continue building TIM3 with perfect documentation continuity!**