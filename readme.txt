A dart shelf server and dart web flutter client.

The dart shelf server provides rest endpoints for accessing several tables in a SQLite database.

every table has a unique integer id.

users - (id, username, password, dob, is_admin, locked)
	dob - date of birth of the user
	
pension_pots table (id, name, amount, dated, interest_rate)
	name - name of the pension pot.
	user_id - this pot is for this user
	amount - the value of the pension at dated date.
	date - snapshot of the amount at this date
	interest_rate - yearly APR for the pension

There can be multiple pots defined per user

drawdowns table (id, pension_pot_id, amount, start_date, end_date, interest_rate)
	user_id - 
	pension_pot_id - this is a drawdown on this pot
	amount - monthly amount taken from the pot
	start_date - start of the drawdown
	end_date - end of the drawdown, this can be null meaning the drawdown continues indefinitely.
	interest_rate - yearly APR to increase this drawdown by to deal with inflation.

state_pensions - (id, user_id, start_age, amount, interest_rate)
	user_id - 
	start_age - the state pension starts at this age for the user indicated
	amount - the monthly income from the state
	interest_rate - increases by this yearly APR to deal with inflation

The web flutter application has crud for all of these tables.

It has a fl_chart output screen
	The server has a simulate end point which calculates the values for the chart.

The chart screen needs to show the following, hence the simulate must calculate the values needed for the chart.

	Show a line for each individual pension pot for the logged in user, the Y axis is to be the amount, the x axis to be the month/year. The origin should be the minimum date from all the pots of the user. The line should be labelled with the name of the pot.
	Show a line which is the sum of all the pot values for said user.
	Show a line the income for the user, the income is the sum of the drawdowns from the pots of the user, and the state_pension (if the user has reached the start_age of the pension).
	This the pension pots should be reducing by the amount of the drawdowns, and increasing my the amount of interest.
	The chart should show the minimum and maximum sum of pots from a monte carlo simulation of the pot performance over 100 years. Hence showing the likelihood of the target values being reached.
	
In answer to your probabler questions, the simulation for monte carlo should be processing the sum of pots input.
When the pot reaches zero just leave it at zero, indicate in the income line that the appropriate drawdown hasn't achieved its value.
Apply interest monthly.
The income is the sum of drawdowns and state_pension, so until state_pension age it will be just the sum of the drawdowns, afterwards its both. But note that drawdowns have a start and end date, those should be taken into account. As once state pension age is reached its likely new drawdowns will come into affect and old ones will stop.
Chart time axis, starts from the earliest pot date, continues until user reaches age 120.


okay i would like some help with a dart shelf rest server and flutter web client. I shall tell you about it, give you the relevant source files and then ask you for fixes/changes. Do not try and suggest anything before i ask, you'd be wasting both my and your time.
I have a chart showing the output from the application, in the app i  add a number of pension pots, each pot has a starting amount, start date, interest rate and can have a number of draw downs against it. The chart plots the pot values over time. So the pot values are varied. Initial value at start of chart, next month value is initial value plus interest earned minus amount drawn down. The repeats for a number of months.

The graph/chart also has a line showing the income earned, this is the sum of the draw down values for that month. The value resets at each month, does not sum over time. Because the pot values are in the 200000 range and the drawdowns in the 1000 range two y axis ranges are needed. The left axis shows the pot value, the right is supposed to show the income value. The income should be scaled so its not tiny at the bottom of the graph and hence unuseable.
I am using fl_chart. It has two axis at present the income one is so messed up i cannot see the values and the income lines are tiny at the bottom.  I don't want a fixed scaling i want the income scaled so dependent on its value it moves up to be shown nicely so max over the entire range is at the top, min at the bottom. Max changes over time as drawdowns have interest rates applied to emulate inflation. And they may go to zero meaning the pot they were associated with is 0 so no income can come from that.

Let me example what i want then you can fix the chart and screen. Left Y-axis should be pot values ranging from 0 at the bottom to sum of pots max at the top. This means that the monte carlo goes off the top but i don't care about that. It should show values in the axis of step say 20000. Right Y-axis should be income values it should real income value so 0 at the bottom to max income at the top. The line should be scales so that it fits this, the hint text when pointing at the line should show the real income value not the scaled. The scale should show axis values in a step of say 500 (presently its just a mush of an infinite number of overlapping text.

i have a dart shelf rest server and dart web flutter client both in separate docker containers. These work fine locallly but when put onto google cloud runner the client does not see/access the server. I can see the client is working as get the login dialogue. I can see the server is working as i can curl to it. To help i want to add logging to both to aid me, how do i do logging in dart in this scenario, i want to make it so i can see logs from both preferrably in the google cloud running logs console. But also needs to work in my local docker. And i want to be able to easily turn it on/off maybe via some environment/compile time setting.

I have a dart shelf rest server with multiple routes, two are public /login and /register the rest e.g. /simulate should be protected by auth/jwt so the client has to login sucessfully via /login before it can use /simulate. This doesn't work i need help fixing this.

I have a dart shelf rest server and a dart web flutter client. I have docker local configuration for this which is working fine. The rest server is in its own container, the web flutter client is in a container along with nginx, so nginx is serving up the flutter client and proxying the client server calls to the rest server. The web client goes to rest view htts://client.../api/login, the nginx is supposed to proxy this and remove the /api so it ends up going to the rest backend at http://server.../login. This works fine in the local docker setup. Putting this setup into gcloud cloud runner, it changes the http to https and changes the url's to match the cloud rest instance and client instance. The client starts up fine, I can see the login page. I attempt to login. the /api/login is correctly translated to /login BUT the https://client is not changed to https://server so the server never sees the call. And hence the client fails with an 405 error. I need you to help me fix this.

i have a dart rest shelf server, it uses a sqlite database. On google cloud runner that database is in the image. I want to be able to backup and restore that database remotely. So i want add rest routes to backup and restore but i want those routes protected by some kind of auth, so only my utility program can access those routes. Write for me the server routes and a dart console application to run locally to access those. The console application should have the cloud url passed to it on the command line along with wether its doing a backup or restore.
