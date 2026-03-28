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
    expansion: "Use ask-user-question tool if there are any points to clarify.",
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
    trigger: "$test_pi",
    description: "Test pi extension via tmux",
    expansion: "Test the pi extension with tmux by spawning a new pi session with `pi --models \"github-copilot/gpt-4o\"`.",
  },
  {
    trigger: "$incentivize",
    description: "Insert a random psychological prompting trick (incentive, challenge, deep breath, stakes, self-check)",
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
  {
    trigger: "$idk",
    description: "Admit when you don't know something",
    expansion: "If you don't know the answer, say 'I don't know' instead of guessing. It's better to admit uncertainty than to provide incorrect information.",
  },
  {
    trigger: "$concise",
    description: "Be concise",
    expansion: "Respond in 3 bullet points.",
  }
];
