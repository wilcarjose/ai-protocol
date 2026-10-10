import { messages } from "@/shared/i18n";

// The demo project's home page, in place of the create-next-app one, which writes its texts in the JSX: here the
// text comes from the translations (.ai/rules/arquitectura.md).
export default function Home() {
  return (
    <main>
      <h1>{messages.home.title}</h1>
    </main>
  );
}
