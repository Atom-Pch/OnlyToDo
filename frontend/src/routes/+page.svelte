<main class="mx-auto max-w-4xl px-4 pt-16 pb-24 text-center sm:px-6 sm:pt-24">
	<h1 class="mb-6 text-4xl leading-tight font-extrabold tracking-tight text-white sm:text-5xl">
		Welcome to the <span
			class="bg-gradient-to-r from-indigo-400 to-purple-500 bg-clip-text text-transparent"
			>To-Do</span
		> App! test
	</h1>

	<p class="mx-auto mb-10 max-w-2xl text-lg leading-relaxed text-gray-400 sm:text-xl">
		This is a simple web application created solely as a vehicle for my DevOps project using Go for
		the backend and SvelteKit for the frontend.
	</p>

	<div class="mb-12 rounded-2xl border border-gray-700 bg-gray-800 p-8 shadow-xl sm:p-10">
		<p class="mb-8 text-lg text-gray-300">
			To get started, create an account or log in to your existing account.
		</p>
		<div class="flex flex-col justify-center gap-4 sm:flex-row">
			<a
				href="/register"
				class="rounded-xl bg-gray-700 px-6 py-3 font-semibold text-white shadow-sm ring-1 ring-gray-600 transition hover:bg-gray-600"
			>
				Create Account
			</a>

			<a
				href="/login"
				class="rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-6 py-3 font-semibold text-white shadow-md transition hover:opacity-90"
			>
				Log In to Continue
			</a>
		</div>

		<div class="mt-8 border-t border-gray-700/50 pt-6">
			<a
				href="/todos"
				class="group inline-flex items-center text-lg font-medium text-indigo-400 transition hover:text-indigo-300"
			>
				Go directly to your To-Do List
				<svg
					xmlns="http://www.w3.org/2000/svg"
					fill="none"
					viewBox="0 0 24 24"
					stroke-width="2"
					stroke="currentColor"
					class="ml-2 h-5 w-5 transform transition-transform group-hover:translate-x-1"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"
					/>
				</svg>
			</a>
		</div>
	</div>

	<div class="mt-20 border-t border-gray-800 pt-16 text-left">
		<div class="mb-12 text-center">
			<h2 class="text-3xl font-bold tracking-tight text-white">Behind the Scenes</h2>
			<p class="mt-3 text-gray-400">
				The CI/CD pipeline and cloud infrastructure powering this application.
			</p>
		</div>

		<div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
			<div
				class="rounded-xl border border-gray-700 bg-gray-800/50 p-6 transition duration-300 hover:bg-gray-800"
			>
				<h3 class="mb-3 flex items-center text-xl font-semibold text-indigo-400">
					<span class="mr-2 text-2xl">💻</span> Web Stack
				</h3>
				<p class="text-sm leading-relaxed text-gray-300">
					The user interface is built with <strong class="text-white">SvelteKit</strong>, providing
					a snappy, client-side experience. It communicates with a custom
					<strong class="text-white">Go (Golang)</strong> REST API, chosen for its high performance and
					concurrency.
				</p>
				<p class="mb-3 text-sm leading-relaxed text-gray-300">
					Alongside reasons above, I also want to code in Typescript and Go!
				</p>
			</div>

			<div
				class="rounded-xl border border-gray-700 bg-gray-800/50 p-6 transition duration-300 hover:bg-gray-800"
			>
				<h3 class="mb-3 flex items-center text-xl font-semibold text-indigo-400">
					<span class="mr-2 text-2xl">🏗️</span> Cloud & IaC
				</h3>
				<p class="text-sm leading-relaxed text-gray-300">
					Hosted entirely on <strong class="text-white">AWS</strong>. The foundational
					infrastructure, including VPCs; Compute resources; and IAM Roles, is provisioned
					declaratively using <strong class="text-white">Terraform</strong>.
				</p>
				<p class="mb-3 text-sm leading-relaxed text-gray-300">
					<s
						><strong class="text-white">Ansible</strong> handles the configuration management and software
						initialization on the servers.</s
					> <i>(Integrated into CI/CD)</i>
				</p>
			</div>

			<div
				class="rounded-xl border border-gray-700 bg-gray-800/50 p-6 transition duration-300 hover:bg-gray-800"
			>
				<h3 class="mb-3 flex items-center text-xl font-semibold text-indigo-400">
					<span class="mr-2 text-2xl">🐳</span> Containerization
				</h3>
				<p class="mb-3 text-sm leading-relaxed text-gray-300">
					The frontend and API are containerized via <strong class="text-white">Docker</strong> and
					run as serverless tasks on <strong class="text-white">Amazon ECS (Fargate)</strong>.
					Traffic is routed via an
					<strong class="text-white">Application Load Balancer (ALB)</strong> with external DNS and SSL
					registrar.
				</p>
			</div>

			<div
				class="rounded-xl border border-gray-700 bg-gray-800/50 p-6 transition duration-300 hover:bg-gray-800"
			>
				<h3 class="mb-3 flex items-center text-xl font-semibold text-indigo-400">
					<span class="mr-2 text-2xl">⚙️</span> CI/CD & Deployments
				</h3>
				<p class="mb-3 text-sm leading-relaxed text-gray-300">
					Every code push triggers a <strong class="text-white">GitLab CI/CD</strong> pipeline
					running <strong class="text-white">Playwright</strong> E2E tests. Successful images are
					pushed to <strong class="text-white">ECR</strong>, where an
					<strong class="text-white">EventBridge/Lambda</strong> integration automatically triggers a
					rolling deployment to ECS.
				</p>
			</div>

			<div
				class="rounded-xl border border-gray-700 bg-gray-800/50 p-6 transition duration-300 hover:bg-gray-800"
			>
				<h3 class="mb-3 flex items-center text-xl font-semibold text-indigo-400">
					<span class="mr-2 text-2xl">📊</span> Observability
				</h3>
				<p class="mb-3 text-sm leading-relaxed text-gray-300">
					The Go backend exposes live application metrics which are routinely scraped by <strong
						class="text-white">Prometheus</strong
					>. These metrics are visualized in real-time through
					<strong class="text-white">Grafana</strong> dashboards, with both tools also running as ECS
					tasks.
				</p>
			</div>

			<div
				class="relative overflow-hidden rounded-xl border border-indigo-900/50 bg-gray-800/30 p-6 transition duration-300 hover:bg-gray-800/50"
			>
				<div
					class="absolute top-0 right-0 rounded-bl-lg bg-indigo-600/80 px-2 py-1 text-xs font-bold text-white"
				>
					Coming Soon
				</div>
				<h3 class="mb-3 flex items-center text-xl font-semibold text-indigo-400/80">
					<span class="mr-2 text-2xl opacity-80">☸️</span> Orchestration
				</h3>
				<p class="mb-3 text-sm leading-relaxed text-gray-400">
					Active development is underway to migrate the application layer from ECS to <strong
						class="text-gray-300">Amazon EKS</strong
					>. This upcoming integration will showcase container orchestration, Helm charts, and
					improved scalable resilience.
				</p>
			</div>
		</div>
	</div>
	<footer class="mt-16 pt-8 border-t border-gray-800 flex flex-col items-center justify-center pb-8">
		<p class="text-gray-500 text-sm mb-4">Built as a full DevOps Project</p>

		<a 
			href="https://github.com/Atom-Pch/TodoWebApp" 
			target="_blank" 
			rel="noopener noreferrer" 
			class="text-gray-400 hover:text-white transition-colors duration-200 flex items-center gap-2 font-medium mb-4"
		>
			<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
				<path fill-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clip-rule="evenodd" />
			</svg>
			View on GitHub (Atom-Pch)
		</a>

		<div class="flex items-center space-x-6">
			<a 
				href="mailto:pchompubutr@gmail.com" 
				class="text-gray-400 hover:text-indigo-400 transition-colors duration-200 flex items-center gap-2 text-sm font-medium group"
			>
				<svg class="w-4 h-4 group-hover:scale-110 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
				</svg>
				Email (pchompubutr@gmail.com)
			</a>

			<span class="text-gray-700">|</span>

			<a 
				href="https://www.linkedin.com/in/parit-chompubutr/" 
				target="_blank" 
				rel="noopener noreferrer" 
				class="text-gray-400 hover:text-indigo-400 transition-colors duration-200 flex items-center gap-2 text-sm font-medium group"
			>
				<svg class="w-4 h-4 group-hover:scale-110 transition-transform" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
					<path fill-rule="evenodd" d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" clip-rule="evenodd"/>
				</svg>
				LinkedIn (Parit Chompubutr)
			</a>
		</div>
	</footer>
</main>
