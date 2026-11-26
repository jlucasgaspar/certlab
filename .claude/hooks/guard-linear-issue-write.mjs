import process from "node:process";

let input = "";

for await (const chunk of process.stdin) {
  input += chunk;
}

let call;

try {
  call = JSON.parse(input);
} catch {
  deny("Não foi possível validar a operação do Linear; a chamada foi bloqueada por segurança.");
}

const toolName = call?.tool_name;
const issueId = call?.tool_input?.id;
const isExistingIssue = typeof issueId === "string" && issueId.trim().length > 0;

if (toolName === "mcp__linear__save_issue" && isExistingIssue) {
  process.exit(0);
}

deny(
  "Claude não pode criar issues no Linear. Use save_issue somente para atualizar uma issue existente e informe seu id, por exemplo LAB-123.",
);

function deny(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: reason,
      },
    }),
  );
  process.exit(0);
}
