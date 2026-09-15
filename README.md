<h1>Secure CI/CD Pipeline with Automated Vulnerability Scanning</h1>

<p>
A beginner-friendly DevOps project where I built a Docker-based CI/CD pipeline
and added security scanning using Trivy.
</p>

<p>
The main idea was simple:
<strong>build the Docker image → scan it → stop the pipeline if serious vulnerabilities are found → push the image to Docker Hub.</strong>
</p>

<hr>

<h2>What I Built</h2>

<p>
I started with a simple static website and containerized it using Docker and Nginx.
After getting the Docker part working, I created a GitHub Actions pipeline to automate
the process.
</p>

<p>
I then added Trivy so that the Docker image is checked for known vulnerabilities
before it gets pushed to Docker Hub.
</p>

<p>
If Trivy finds a <strong>HIGH</strong> or <strong>CRITICAL</strong> vulnerability,
the GitHub Actions job fails and the image is not pushed.
</p>

<h2>Project Flow</h2>

<pre>
GitHub Push
    ↓
GitHub Actions
    ↓
Build Docker Image
    ↓
Trivy Security Scan
    ↓
 ┌───────────────┐
 │ Vulnerability?│
 └───────┬───────┘
         │
    ┌────┴────┐
    ↓         ↓
   YES        NO
    ↓         ↓
  FAIL       Continue
              ↓
        Docker Hub Push
</pre>

<hr>

<h2>Tools I Used</h2>

<ul>
  <li>Git &amp; GitHub</li>
  <li>GitHub Actions</li>
  <li>Docker</li>
  <li>Nginx</li>
  <li>Trivy</li>
  <li>Bash</li>
  <li>Docker Hub</li>
</ul>

<p>
I intentionally kept the project small instead of adding a lot of different tools.
The goal was to understand the CI/CD and security flow properly.
</p>

<hr>

<h2>Project Structure</h2>

<pre>
secure-ci-cd-pipeline/
│
├── website/
│   └── index.html
│
├── Dockerfile
├── scan.sh
│
└── .github/
    └── workflows/
        └── ci-cd.yml
</pre>

<hr>

<h2>1. Creating the Website</h2>

<p>
First, I created a basic static website inside the <code>website</code> folder.
There was nothing complicated here. I just needed a small application that I could
containerize and use for the DevOps pipeline.
</p>

<pre>
website/
└── index.html
</pre>

<hr>

<h2>2. Creating the Dockerfile</h2>

<p>
I used Nginx to serve the static website.
My Dockerfile ended up looking like this:
</p>

<pre>
FROM nginx:alpine

RUN apk update &amp;&amp; apk upgrade

COPY website /usr/share/nginx/html

EXPOSE 80
</pre>

<p>
The important part for me was understanding what each instruction was doing.
</p>

<ul>
  <li><code>FROM nginx:alpine</code> gives me an Nginx-based container.</li>
  <li><code>apk update &amp;&amp; apk upgrade</code> updates the Alpine packages.</li>
  <li><code>COPY</code> puts my website inside Nginx's web directory.</li>
  <li><code>EXPOSE 80</code> documents the port used by Nginx.</li>
</ul>

<hr>

<h2>3. Building and Running the Docker Container</h2>

<p>
Before touching GitHub Actions, I wanted to make sure the Docker image worked locally.
</p>

<pre>
docker build --no-cache -t secure-ci-cd .
</pre>

<p>
Then I started the container:
</p>

<pre>
docker run -d -p 8080:80 --name secure-ci-cd-container secure-ci-cd
</pre>

<p>
After that, I opened:
</p>

<pre>
http://localhost:8080
</pre>

<p>
The website was running successfully inside the Docker container.
</p>

<hr>

<h2>4. Adding Trivy</h2>

<p>
Once Docker was working, I wanted to check whether the image contained known
security vulnerabilities.
</p>

<p>
For this, I used Trivy.
</p>

<p>
The command I used for local testing was:
</p>

<pre>
trivy image --severity HIGH,CRITICAL --exit-code 1 secure-ci-cd
</pre>

<p>
The two important options here are:
</p>

<ul>
  <li><code>--severity HIGH,CRITICAL</code> tells Trivy which severity levels I want to check.</li>
  <li><code>--exit-code 1</code> makes Trivy return a failure status when matching vulnerabilities are found.</li>
</ul>

<p>
In GitHub Actions, I used the Trivy Action instead of writing the CLI command directly:
</p>

<pre>
- name: Trivy Security Scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: secure-ci-cd
    severity: HIGH,CRITICAL
    exit-code: '1'
</pre>

<p>
The <code>severity</code> and <code>exit-code</code> settings in the GitHub Action
perform the same basic configuration as the corresponding Trivy CLI options
used during local testing.
</p>

<hr>

<h2>5. Testing the Security Check</h2>

<p>
I didn't want to assume that the security check worked. I wanted to actually test
the failure case.
</p>

<p>
So I temporarily changed the Dockerfile to use an old Nginx image:
</p>

<pre>
FROM nginx:1.14
</pre>

<p>
When I scanned the image, Trivy found HIGH and CRITICAL vulnerabilities.
The pipeline failed.
</p>

<p>
This was actually a good result because it showed that the security check was
blocking the vulnerable image instead of just displaying the vulnerabilities.
</p>

<hr>

<h2>6. Fixing the Vulnerabilities</h2>

<p>
After testing the failure case, I changed the base image back to:
</p>

<pre>
FROM nginx:alpine
</pre>

<p>
But even then, Trivy initially found some HIGH vulnerabilities in the packages
inside the Alpine image.
</p>

<p>
I added:
</p>

<pre>
RUN apk update &amp;&amp; apk upgrade
</pre>

<p>
Then I rebuilt the image:
</p>

<pre>
docker build --no-cache -t secure-ci-cd .
</pre>

<p>
At the time I tested it, the scan showed:
</p>

<pre>
0 vulnerabilities
</pre>

<p>
This result only represents the scan at that point in time. It is not a permanent
guarantee that the image will always have zero vulnerabilities. New vulnerabilities
can be discovered in Nginx or Alpine packages later, so the image should be scanned
again as part of the CI/CD process.
</p>

<hr>

<h2>7. Creating the GitHub Actions Pipeline</h2>

<p>
After getting everything working locally, I moved the process into GitHub Actions.
</p>

<p>
The workflow is stored at:
</p>

<pre>
.github/workflows/ci-cd.yml
</pre>

<p>
The workflow first builds the Docker image, scans it with Trivy, and only pushes
the image if the security scan passes.
</p>

<pre>
name: Secure CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  security-pipeline:
    runs-on: ubuntu-latest

    steps:

      - name: Checkout code
        uses: actions/checkout@v5

      - name: Build Docker image
        run: docker build --no-cache -t secure-ci-cd .

      - name: Trivy Security Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: secure-ci-cd
          severity: HIGH,CRITICAL
          exit-code: '1'

      - name: Login to Docker Hub
        uses: docker/login-action@v4
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push Docker image
        run: |
          docker tag secure-ci-cd ${{ secrets.DOCKER_USERNAME }}/secure-ci-cd:latest
          docker tag secure-ci-cd ${{ secrets.DOCKER_USERNAME }}/secure-ci-cd:${{ github.sha }}

          docker push ${{ secrets.DOCKER_USERNAME }}/secure-ci-cd:latest
          docker push ${{ secrets.DOCKER_USERNAME }}/secure-ci-cd:${{ github.sha }}
</pre>

<p>
I use two tags here:
</p>

<ul>
  <li><code>latest</code> gives me a simple tag for the most recent image.</li>
  <li><code>${{ github.sha }}</code> gives each image a unique tag based on the Git commit.</li>
</ul>

<p>
The commit-based tag is useful because I can identify exactly which Git commit
created a particular Docker image instead of relying only on <code>latest</code>.
</p>

<hr>

<h2>8. Adding Docker Hub</h2>

<p>
After the security scan was working, I added Docker Hub so that the final Docker
image could be stored in a container registry.
</p>

<p>
I created a Docker Hub repository called:
</p>

<pre>
secure-ci-cd
</pre>

<p>
I then added these GitHub repository secrets:
</p>

<ul>
  <li><code>DOCKER_USERNAME</code></li>
  <li><code>DOCKER_PASSWORD</code></li>
</ul>

<p>
For <code>DOCKER_PASSWORD</code>, I used a Docker Hub access token rather than
putting my actual password inside the workflow.
</p>

<p>
The workflow accesses these values through GitHub Secrets:
</p>

<pre>
${{ secrets.DOCKER_USERNAME }}
${{ secrets.DOCKER_PASSWORD }}
</pre>

<p>
These are GitHub Actions secret references, not the actual credentials.
I made sure not to commit any real Docker Hub password or access token to the
repository.
</p>

<hr>

<h2>9. Bash Scan Script</h2>

<p>
I also created a Bash script called <code>scan.sh</code> while working on the
Trivy scanning part.
</p>

<p>
The purpose of the script was to run the scan and save the result as a report.
</p>

<pre>
#!/bin/bash

IMAGE_NAME=$1

mkdir -p reports

trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --format table \
  --output reports/scan-report.txt \
  "$IMAGE_NAME"

TRIVY_EXIT_CODE=$?

if [ $TRIVY_EXIT_CODE -ne 0 ]; then
    echo "HIGH or CRITICAL vulnerabilities found!"
    exit 1
fi

echo "No HIGH or CRITICAL vulnerabilities found."
echo "Scan report saved to reports/scan-report.txt"
</pre>

<p>
I later used the official Trivy GitHub Action in the main CI/CD workflow because
it made the GitHub Actions implementation simpler and more reliable.
</p>

<hr>

<h2>Problems I Faced</h2>

<h3>Problem 1 — Old Nginx Image Had Vulnerabilities</h3>

<p>
I started with an older Nginx image and Trivy reported several vulnerabilities.
</p>

<p>
<strong>What I learned:</strong> The base image matters. Using an old image can
bring known vulnerabilities into the final container.
</p>

<p>
<strong>Fix:</strong> I moved to <code>nginx:alpine</code> and updated the
packages inside the image.
</p>

<hr>

<h3>Problem 2 — Alpine Image Still Had Vulnerabilities</h3>

<p>
Changing to Alpine reduced the number of vulnerabilities, but the scan still
reported some HIGH vulnerabilities.
</p>

<p>
<strong>Fix:</strong>
</p>

<pre>
RUN apk update &amp;&amp; apk upgrade
</pre>

<p>
After rebuilding, the scan showed no HIGH or CRITICAL vulnerabilities at the
time of testing.
</p>

<hr>

<h3>Problem 3 — Trivy Was Not Blocking the Pipeline</h3>

<p>
At one point, Trivy was able to show the vulnerabilities, but the pipeline
wasn't behaving the way I expected.
</p>

<p>
The important thing I was missing was the exit code.
</p>

<pre>
--exit-code 1
</pre>

<p>
This tells Trivy to return a failure status when the selected vulnerabilities
are found.
</p>

<hr>

<h3>Problem 4 — GitHub Actions Returned Exit Code 126</h3>

<p>
When I tried running <code>scan.sh</code> through GitHub Actions, I got:
</p>

<pre>
exit code 126
</pre>

<p>
The problem was that Git had not recorded the script as executable.
</p>

<p>
The file was tracked as:
</p>

<pre>
100644
</pre>

<p>
instead of:
</p>

<pre>
100755
</pre>

<p>
I fixed it using:
</p>

<pre>
chmod +x scan.sh
git update-index --chmod=+x scan.sh
</pre>

<p>
Then I checked the Git permissions with:
</p>

<pre>
git ls-files --stage scan.sh
</pre>

<p>
This was a useful Linux/Git issue to run into because I learned that
<code>chmod</code> permissions can also matter inside CI/CD.
</p>

<hr>

<h3>Problem 5 — Local and GitHub Scans Were Not Behaving the Same</h3>

<p>
I also ran into a situation where the local Trivy scan passed, but the GitHub
Actions workflow was failing.
</p>

<p>
After troubleshooting it, I switched the GitHub Actions step to the official
Trivy Action:
</p>

<pre>
aquasecurity/trivy-action
</pre>

<p>
After that change, the workflow worked correctly.
</p>

<p>
I kept the Bash script in the project because it helped me understand how the
Trivy command and exit codes work, but the official Action was a cleaner choice
for the GitHub Actions workflow.
</p>

<hr>

<h2>Understanding Exit Codes</h2>

<table>
  <tr>
    <th>Exit Code</th>
    <th>Meaning</th>
  </tr>
  <tr>
    <td><code>0</code></td>
    <td>Command completed successfully</td>
  </tr>
  <tr>
    <td><code>1</code></td>
    <td>Command detected a failure condition</td>
  </tr>
  <tr>
    <td><code>126</code></td>
    <td>Command was found but could not be executed</td>
  </tr>
</table>

<p>
Understanding exit codes was important because GitHub Actions uses the exit
status of commands to determine whether a step succeeds or fails.
</p>

<hr>

<h2>Final Result</h2>

<p>
At the end, I had a working pipeline that runs automatically whenever I push
code to the <code>main</code> branch:
</p>

<ol>
  <li>GitHub Actions checks out the code.</li>
  <li>The Docker image is built.</li>
  <li>Trivy scans the image.</li>
  <li>HIGH and CRITICAL vulnerabilities cause the pipeline to fail.</li>
  <li>If the scan passes, GitHub logs in to Docker Hub.</li>
  <li>The image gets both a <code>latest</code> tag and a Git commit SHA tag.</li>
  <li>The images are pushed to Docker Hub.</li>
</ol>

<hr>

<h2>Final Pipeline</h2>

<pre>
Git Push
   ↓
GitHub Actions
   ↓
Docker Build
   ↓
Trivy Scan
   ↓
Security Check
   ├── HIGH/CRITICAL → ❌ Stop
   │
   └── Scan Passed
          ↓
     Docker Login
          ↓
     Docker Tag
       ├── latest
       └── Git SHA
          ↓
     Docker Hub Push
</pre>

<hr>

<h2>What I Learned From This Project</h2>

<ul>
  <li>How to create a Docker image using a Dockerfile.</li>
  <li>How to run a static website inside an Nginx container.</li>
  <li>How GitHub Actions can automate a CI/CD process.</li>
  <li>How Trivy can be used for Docker image security scanning.</li>
  <li>Why exit codes are important in CI/CD.</li>
  <li>How GitHub Secrets can be used for Docker credentials.</li>
  <li>How to push Docker images to Docker Hub from GitHub Actions.</li>
  <li>Why versioned Docker tags are useful.</li>
  <li>How Linux executable permissions can affect CI/CD scripts.</li>
  <li>How to troubleshoot failed GitHub Actions jobs instead of just rerunning them.</li>
</ul>

<hr>

<h2>Security Check Before Publishing</h2>

<p>
Before making the repository public, I checked that no real credentials were
committed to the project.
</p>

<p>
In particular, I made sure there were no Docker Hub passwords, access tokens,
GitHub tokens, or other secrets inside the source files, workflow files,
README, or Git history.
</p>

<p>
Only GitHub Secret references such as
<code>${{ secrets.DOCKER_PASSWORD }}</code> are used in the workflow.
</p>

<hr>

<h2>Why I Built This</h2>

<p>
I wanted to build something small enough to understand properly but still close
to a real DevOps workflow.
</p>

<p>
The biggest thing I learned from this project was that CI/CD is not just about
building and pushing an image. Security checks can be added into the pipeline
so that a vulnerable image doesn't automatically move to the next stage.
</p>

<p align="center">
  <strong>Build → Scan → Block → Push</strong>
</p>

<hr>

<p align="center">
  <i>Built as a hands-on DevOps learning project.</i>
</p>
