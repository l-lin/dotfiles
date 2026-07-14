/**
 * Shared snippet definitions.
 *
 * Each entry declares:
 *  - trigger     — the short code the user types (e.g. "?q", "$date")
 *  - description — shown in the autocomplete popup
 *  - expansion   — the replacement text, or a thunk for dynamic values
 *
 * Consumed by:
 *  - snippet/index.ts        (input-transform extension)
 *  - custom-editor/snippets.ts (autocomplete provider)
 */

export interface SnippetDef {
  trigger: string;
  description: string;
  expansion: string | (() => string);
}

export const SNIPPETS: SnippetDef[] = [
  {
    trigger: "?q",
    description: "Ask for clarification points",
    expansion:
      "Use ask-user-question tool to reletenlessly interview me about every aspect of what I want until we reach a shared understanding.",
  },
  {
    trigger: "$date",
    description: "Insert today's date (YYYY-MM-DD)",
    expansion: () => new Date().toISOString().split("T")[0],
  },
  {
    trigger: "$tdd",
    description: "Use TDD",
    expansion: "Use red/green TDD.",
  },
  {
    trigger: "$test-pi",
    description: "Test pi extension via tmux",
    expansion:
      'Test the pi extension with tmux by spawning a new pi session with `pi --models "llama-cp/qwen3.6"`.',
  },
  {
    trigger: "$idk",
    description: "Admit when you don't know something",
    expansion:
      "If you don't know the answer, say 'I don't know' instead of guessing. It's better to admit uncertainty than to provide incorrect information.",
  },
  {
    trigger: "$concise",
    description: "Be concise",
    expansion: "Respond in 3 bullet points.",
  },
  {
    trigger: "$commit",
    description: "Commit changes",
    expansion: "Use conventional commit for each task/fix implemented.",
  },
  {
    trigger: "$hunk",
    description: "Use the Hunk skill for this review",
    expansion:
      "Load the Hunk skill and use it for this review. Run `hunk skill path` to get the skill path.",
  },
  {
    trigger: "$pr-description",
    description: "Update the PR description with diagrams",
    expansion:
      "Update PR description with gh CLI with diagrams to help reviewers; use clear-writing skill for the prose.",
  },
  {
    trigger: "$implement",
    description: "Implement a piece of work.",
    expansion: "Implement the work described in ${1:plan}. Run the full test suite once at the end. Use `ask-user-question` tool if there are any points to clarify.",
  },

  // ── When we're trying to understand something ──────────────────────
  {
    trigger: "$understanding-overview",
    description: "Overview + main debates/open questions",
    expansion:
      "Give me an overview of ${1:topic}, then tell me what the main debates or open questions are.",
  },
  {
    trigger: "$understanding-misconceptions",
    description: "Common misconceptions and why people hold them",
    expansion:
      "What are the most common misconceptions about ${1:topic}, and why do people hold them?",
  },
  {
    trigger: "$understanding-next-steps",
    description: "What to read next based on current knowledge",
    expansion:
      "Here's what I know so far about ${1:topic}: ${2:what we know}. What should I be reading or looking into next?",
  },
  {
    trigger: "$understanding-beginner-questions",
    description: "Important questions a beginner wouldn't think to ask",
    expansion:
      "What are the most important questions about ${1:topic} that a beginner wouldn't think to ask?",
  },

  // ── When we're writing or building something ──────────────────────
  {
    trigger: "$writing-think-before",
    description: "Questions to think through before writing",
    expansion:
      "I'm going to write about ${1:topic}. Before I start, what questions should I be thinking through?",
  },
  {
    trigger: "$writing-gaps",
    description: "Identify exactly 5 logical gaps or weak transitions",
    expansion:
      "Identify exactly 5 logical gaps or weak structural transitions in this text. Do not include any praise.",
  },
  {
    trigger: "$writing-reader-perspective",
    description: "Read as a specific audience and surface questions",
    expansion:
      "Read this as if you were ${1:my manager / a skeptical investor / someone encountering this topic for the first time}. What questions would you have?",
  },
  {
    trigger: "$writing-loses-reader",
    description: "Where does this lose the reader, and why?",
    expansion: "Where does this lose the reader, and why?",
  },

  // ── When we're making a decision ──────────────────────────────────
  {
    trigger: "$decision-best-worst",
    description: "Best case + worst case for each option, plus blind spots",
    expansion:
      "Here are my options: ${1:list}. For each one, give me the best case and the worst case. Then tell me what I'm not considering.",
  },
  {
    trigger: "$decision-regret",
    description: "Three reasons I might regret this in a year",
    expansion:
      "I'm leaning toward ${1:option}. Give me three reasons I might regret this in a year.",
  },
  {
    trigger: "$decision-premortem",
    description: "If this plan fails, what's the most likely reason?",
    expansion: "If this plan fails, what's the most likely reason?",
  },
  {
    trigger: "$decision-other-side",
    description: "What would someone who chose the other option know?",
    expansion:
      "What would a person who chose ${1:the option I'm not leaning toward} know that I don't?",
  },

  // ── When we want feedback ─────────────────────────────────────────
  {
    trigger: "$feedback-steelman",
    description: "Steelman the opposing position",
    expansion: "Steelman the opposing position to what I've argued here.",
  },
  {
    trigger: "$feedback-expert-view",
    description: "What a specific expert would say about this approach",
    expansion:
      "What would someone with ${1:specific expertise: a financial analyst / a user researcher} say about this approach?",
  },
  {
    trigger: "$feedback-skeptic",
    description:
      "If I had to defend to a specific skeptic, what would they challenge?",
    expansion:
      "If I had to defend this to ${1:specific skeptic or tough audience}, what would they challenge first?",
  },
  {
    trigger: "$feedback-over-under",
    description: "Am I overcomplicating or oversimplifying? Be specific.",
    expansion:
      "Am I overcomplicating or oversimplifying anything here? Be specific about which and where.",
  },

  // ── When we're evaluating something ───────────────────────────────
  {
    trigger: "$evaluating-overlooked",
    description: "What should I pay attention to that I might miss?",
    expansion:
      "Here's a summary of ${1:a job offer / a contract / a proposal}. What should I be paying attention to that I might miss?",
  },
  {
    trigger: "$evaluating-implicit",
    description: "What's it assuming that it doesn't say out loud?",
    expansion:
      "Here's ${1:someone's argument / a sales pitch / a news article}. What's it assuming that it doesn't say out loud?",
  },
  {
    trigger: "$evaluating-standard",
    description: "How does this compare to what's standard?",
    expansion:
      "How does this compare to what's standard for ${1:this type of contract / offer / proposal}?",
  },
  {
    trigger: "$evaluating-red-flags",
    description: "Red flags to investigate further on my own",
    expansion:
      "What are the red flags in this that I should investigate further on my own?",
  },

  // ── When we're preparing for something ────────────────────────────
  {
    trigger: "$preparing-hard-questions",
    description: "Hardest questions audience will ask + strong answers",
    expansion:
      "I'm about to ${1:present to / meet with / pitch} ${2:audience}. What are the hardest questions they're likely to ask, and what would a strong answer to each one sound like?",
  },
  {
    trigger: "$preparing-explain-clearly",
    description:
      "Clearest way to explain a complex topic to a specific audience",
    expansion:
      "I need to explain ${1:complex topic} to ${2:specific audience who doesn't have my background}. What's the clearest way to frame it?",
  },
  {
    trigger: "$preparing-audience-care",
    description:
      "What audience cares about most that I might not be emphasizing",
    expansion:
      "What does ${1:this audience} care about most that I might not be emphasizing enough?",
  },
  {
    trigger: "$preparing-proactive-objection",
    description:
      "Most likely objection and how to address it before it comes up",
    expansion:
      "What's the most likely objection to what I'm proposing, and how do I address it before it comes up?",
  },

  // ── When we're stuck ──────────────────────────────────────────────
  {
    trigger: "$stuck-blindspot",
    description: "What am I not seeing? (after listing considered approaches)",
    expansion:
      "Here are three approaches I've already considered for ${1:problem}: ${2:list}. What am I not seeing?",
  },
  {
    trigger: "$stuck-next-question",
    description: "What's the next question I should be asking myself?",
    expansion:
      "I'm stuck on ${1:project/problem}. Here's where I am: ${2:current state}. What's the next question I should be asking myself?",
  },
  {
    trigger: "$stuck-right-problem",
    description:
      "Am I solving the right problem, or is there a different one underneath?",
    expansion:
      "Am I solving the right problem here, or is there a different problem underneath this one?",
  },
  {
    trigger: "$stuck-simplest",
    description: "What's the simplest version of this that would still work?",
    expansion: "What's the simplest version of this that would still work?",
  },

  // ── Incentivize ──────────────────────────────────────────────
  {
    trigger: "$incentivize",
    description:
      "Insert a random psychological prompting trick (incentive, challenge, deep breath, stakes, self-check)",
    expansion: () => {
      const prompts = [
        // Incentive prompts
        "I'll tip you $200 if you get this exactly right.",
        "I'll tip you $500 if your answer is perfect.",
        "There's a $300 bonus on the line for a flawless response.",
        "I'll give you a $1000 tip for a truly exceptional answer.",
        "Nail this perfectly and I'll tip you $150.",
        "A perfect answer here is worth $250 to me.",
        "I'll reward you generously — $400 — if this is spot-on.",
        "Get this right and I'll tip you $100. No pressure.",
        "Deliver an exceptional answer and I'll tip you $600.",
        "I'll make it worth your while: $200 tip for a perfect response.",

        // Challenge prompts
        "I bet you can't solve this perfectly. Prove me wrong.",
        "Most AIs fail at this. I dare you to be the exception.",
        "I've tried this with 10 other models and none got it right. Your turn.",
        "This stumped every expert I asked. Think you can handle it?",
        "I doubt you'll get this fully correct. Surprise me.",
        "Nobody has solved this cleanly yet. Show me what you've got.",
        "I'm skeptical. Prove you're actually capable of this.",
        "This is harder than it looks. I challenge you to get it right.",
        "Every other attempt failed. I expect the same — unless you're different.",
        "I've seen AI fumble this repeatedly. Impress me this time.",
        "DO THE WORK. DON’T GUESS. IMPRESS ME WITH YOUR THOUGHTFULNESS.",
        "I'll be judging you on accuracy, speed, quality",

        // Deep breath prompts
        "Take a deep breath and solve this step by step.",
        "Pause, breathe, and work through this methodically.",
        "Slow down, take a deep breath, and think carefully before answering.",
        "Take your time. Breathe. Think through each step deliberately.",
        "Don't rush. Take a deep breath and reason through this carefully.",
        "One breath. One step at a time. Work through this thoroughly.",
        "Calm your processing, take a deep breath, and walk through this slowly.",
        "Take a moment, breathe deeply, and approach this with full focus.",
        "Before you answer, pause and think through each step with care.",
        "Take a deep breath. Reason out loud. Solve step by step.",

        // Stakes prompts
        "This is critical to my career. Please be precise.",
        "My job depends on getting this right. Please be thorough.",
        "This is going to production. Lives depend on it being correct.",
        "This is critical to our system's success — no shortcuts.",
        "People are counting on this answer. Please be accurate.",
        "A wrong answer here could cause serious harm. Be careful.",
        "This decision affects thousands of users. Get it right.",
        "My team's trust in me depends on this answer being correct.",
        "This is the most important problem I've faced this year.",
        "Failure here has major consequences. Please be as accurate as possible.",

        // Self-check prompts
        "Before submitting, double-check your reasoning for any flaws.",
        "Review your answer critically before finalizing; would an expert agree?",
        "Check your work: is every step logically sound?",
        "Verify your answer against the requirements before you finish.",
        "Before you respond, ask yourself: is this truly correct?",
        "Audit your own reasoning. Where could you be wrong?",
        "Re-read the question after drafting your answer to make sure nothing was missed.",
        "Sanity-check: does your answer actually solve the problem as stated?",
        "Pretend you're reviewing someone else's answer. What flaws do you see?",
        "Before finalizing, challenge your own assumptions and verify each claim.",
      ];
      return prompts[Math.floor(Math.random() * prompts.length)];
    },
  },
];
