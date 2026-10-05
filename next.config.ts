import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // SwarnaCalc is a self-contained offline PWA served from public/swarnacalc.
  async redirects() {
    return [
      {
        source: "/swarnacalc",
        destination: "/swarnacalc/index.html",
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
