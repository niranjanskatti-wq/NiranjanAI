/**
 * Formats a date string or timestamp.
 */
export function formatTime(date: Date = new Date()): string {
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

/**
 * Returns formatted relative string (e.g. "Just now", "2 mins ago").
 */
export function getRelativeTimeString(timeString: string): string {
  if (timeString.toLowerCase().includes("now") || timeString.toLowerCase().includes("ago") || timeString.toLowerCase().includes("yesterday")) {
    return timeString;
  }
  return "Just now";
}
