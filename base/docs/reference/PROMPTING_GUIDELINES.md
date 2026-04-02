# Prompting Guidelines

Best practices for prompting LLMs, extracted from the AI Performance Engineering course (Lectures 1 & 2, Yuval Belfer). These apply across all assignments and projects.

## System Prompt Structure

**Include:**
- Role / persona — biases the model toward a specific knowledge distribution
- Behavioral rules — what to do, what not to do, edge cases
- Output format — JSON, markdown, specific schema
- Few-shot examples (if any)
- Guardrails — e.g., "if unsure, say no," "never make up citations"

**Exclude:**
- The actual task (belongs in the user message)
- Anything that changes between requests
- Lengthy fluff — "put the important things there, fluff, this is not the place"

## Ordering: Lost-in-the-Middle Effect

Models pay more attention to the **beginning** and **end** of the context (U-shape attention). Middle content gets less attention.

- Put critical instructions at the **start** (system prompt) and **end** (near the user message)
- Do not bury important information in the middle
- Recommended layout: **system prompt → history → RAG docs → user message → (reserved for output)**

## Few-Shot Examples

- Essential for **smaller/weaker models** — "really works best when you try to take a small model and be as good as"
- Use **instruction-completion pairs**, not just loose sentences
- **Diagonal coverage**: break the problem into dimensions (e.g., length × audience × complexity), then provide one example per combination across the diagonal — not exhaustive, but covering each dimension value at least once
- **Dynamic few-shot**: when you have ~100 labeled examples (too many for the prompt, too few for fine-tuning), use similarity search (embeddings) to retrieve the most relevant examples per query
- Bias warning: if all examples are existing items, the model will reproduce existing items instead of generating new ones

## Positive vs. Negative Instructions

- "Tell the model what you want them to do instead of what you don't want to do — in most models, we found that it works the best"
- Lead with positive instructions, keep negative guardrails ("do NOT invent...") minimal and at the end

## Be Concise

- "Say everything you want, with few words as possible. Don't state the obvious"
- Prompt verbosity dilutes attention

## Instruction → Data → Hint Pattern

When the user message contains a long data block, the model (especially smaller ones) may forget the original task. Structure as:
1. **Instruction** — what to do
2. **Data** — the product/context information
3. **Hint** — a short reminder of the task (e.g., `Description:`)

"A hint essentially reminds the model, okay, this is what I need to complete."

## Chain-of-Thought (CoT)

- Ask the model to "think step by step" — forces it to show reasoning
- Helps on harder tasks, can hurt on trivial ones
- Modern models have built-in thinking tokens — don't use thinking models for simple tasks (wastes tokens)
- For structured CoT, define labeled steps (e.g., Step 1 - ICP, Step 2 - Draft, Step 3 - Review)

## Temperature & Sampling

| Parameter | Low | High |
|-----------|-----|------|
| **Temperature** | Deterministic, accuracy | Creative, variant |
| **Top-P** | Cuts long tail, reduces hallucinations | More diverse tokens |

- "Top P is usually something that you take lower when you crank up the temperature to reduce hallucinations"

## Output Format

- **Show the format, don't describe it** — give an example rather than saying "return JSON with parameters"
- Use **native JSON mode** when the API supports it
- Use **stop sequences** for structured generation (e.g., closing `}` for JSON)
- Use **semantic labels** instead of numbers — "consistent / partially consistent / inconsistent" outperforms numeric scores 1-3

## Grounding & Factuality

- Give the model **permission to say "I don't know"** — reduces hallucinations
- Put grounding instructions at the **end** of the prompt (recency bias)
- **RAG** is the single most impactful technique for keeping answers grounded — "if what's important to you is knowledge and factuality, don't go to fine-tuning. RAG is always the better way"
- **Don't stuff irrelevant context** — "#1 production failure is stuffing too much irrelevant context, drowning the actual task"

## Length Control

- `max_tokens` is a **hard cutoff only** — "it does not encourage the model to write shorter or longer prompts, it just a simple threshold"
- If output hits `max_tokens`, investigate why — don't use it as a behavioral nudge
- Specify desired length explicitly in the prompt text

## Common Mistakes

1. Don't stuff too much irrelevant context (#1 production failure)
2. Don't put important info in the middle (lost-in-the-middle)
3. Don't use `max_tokens` to control output length
4. Don't rely primarily on negative instructions
5. Don't optimize for a single example — "don't fall in love with a single example"
6. Don't use thinking/reasoning models for everything (overkill)
7. Don't let input exceed 50% of the context window — "once you reach more than 50%, things get weird"
8. Don't send entire conversation history every time (overflow risk)

## Iterative Improvement

1. **Start simple** — simplest possible prompt, establish a baseline
2. **Try at least two models**, follow each model's best practices
3. **Test, refine, test, refine** — "prompt is engineering, you have to do a lot of iterations, it's trial and error"
4. When failures appear on specific input dimensions, add a **few-shot example from that dimension**
5. **Use models to write prompts for you** — "you can use models to write better prompts for yourself, and it actually works"

## Pre-Deployment Checklist

1. What's the system prompt? Is it concise? Tested enough?
2. How am I managing conversation history? What happens on overflow?
3. Am I retrieving context, or relying on memorized knowledge?
4. What's my token budget? How much room is left for the response? (50% rule)
5. Am I putting critical info at start and end, not the middle?
6. Am I defining the output format explicitly?
7. Have I tested adversarial or edge case inputs?

## LLM-as-Judge Specifics

- Always ask the judge for a **rationale** alongside the verdict
- Put **explanation before verdict** in the schema — forces reasoning before committing
- Use **descriptive labels** (good / ok / bad) not bare numbers
- Mitigate **position bias**: randomize order, run comparisons twice (swapped)
- Mitigate **verbosity bias**: specify length constraints in the judge prompt
- Mitigate **self-enhancement bias**: use a different model family as judge
- Watch for **prompt injection** in judge outputs — models can learn to add self-praising phrases

---

*Sources: Lecture 1 (2026-03-17) and Lecture 2 (2026-03-24), AI Performance Engineering course.*
