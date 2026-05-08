<main class="max-w-3xl mx-auto pt-16 sm:pt-24 pb-12 px-4 sm:px-6 text-center">
	<h1 class="text-4xl sm:text-5xl font-extrabold tracking-tight text-white mb-6 leading-tight">
		Welcome to the <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-purple-500">To-Do</span> App!
	</h1>
	
	<p class="text-lg sm:text-xl text-gray-400 mb-10 leading-relaxed max-w-2xl mx-auto">
		This is a simple web application created solely as a vehicle for my DevOps project using Go for the backend and Sveltekit for the frontend.
	</p>
	
	<div class="bg-gray-800 rounded-2xl p-8 sm:p-10 shadow-xl border border-gray-700 mb-10">
		<p class="text-gray-300 mb-8 text-lg">To get started, create an account or log in to your existing account.</p>
		<div class="flex flex-col sm:flex-row gap-4 justify-center">
			<a href="/register" class="px-6 py-3 rounded-xl font-semibold bg-gray-700 text-white hover:bg-gray-600 transition shadow-sm ring-1 ring-gray-600">
				Create Account
			</a>

			<a href="/login"class="px-6 py-3 rounded-xl font-semibold bg-gradient-to-r from-indigo-600 to-purple-600 text-white hover:opacity-90 transition shadow-md">
				Log In to Continue
			</a>
		</div>
	</div>

	<div class="pt-8 border-t border-gray-800/80">
		<a href="/todos" class="group inline-flex items-center text-indigo-400 hover:text-indigo-300 font-medium transition text-lg">
			Go directly to your To-Do List
			<svg class="ml-2 w-5 h-5 transform group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
		</a>
	</div>
</main>