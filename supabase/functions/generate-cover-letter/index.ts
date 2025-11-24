import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { jobTitle, company, description, resumeUrl } = await req.json()

        // Get OpenAI API key from environment
        const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')
        if (!OPENAI_API_KEY) {
            throw new Error('OpenAI API key not configured')
        }

        // Build prompt
        let prompt = `Write a professional cover letter for the following job application:\n\n`
        prompt += `Job Title: ${jobTitle}\n`
        if (company) prompt += `Company: ${company}\n`
        if (description) prompt += `\nJob Description:\n${description}\n`

        if (resumeUrl) {
            prompt += `\nPlease review the referenced resume as PDF, and write a cover letter that highlights how the candidate's experience and skills align with this position.`
        } else {
            prompt += `\nPlease write a professional cover letter for this position.`
        }

        prompt += `\n\nKeep the tone professional yet personable, and limit to 3-4 paragraphs.`

        // Call OpenAI API
        const response = await fetch('https://api.openai.com/v1/responses', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${OPENAI_API_KEY}`,
            },
            body: JSON.stringify({
                model: 'gpt-5',
                input: [
                    {
                        role: 'system',
                        content: 'You are a helpful assistant that writes professional, compelling cover letters tailored to job descriptions and candidate backgrounds.',
                    },
                    {
                        role: 'user',
                        content: [
                            { type: 'input_text', text: prompt },
                            ...(resumeUrl ? [{ type: 'input_file', file_url: resumeUrl }] : [])
                        ]
                    }
                ]
            }),
        })

        if (!response.ok) {
            const error = await response.text()
            throw new Error(`OpenAI API error: ${error}`)
        }

        const data = await response.json()

        // Parse GPT-5 response
        const message = data.output?.find((o: any) => o.type === 'message')
        const content = message?.content?.find((c: any) => c.type === 'output_text')

        if (!content?.text) {
            throw new Error('Invalid response from OpenAI')
        }

        return new Response(
            JSON.stringify({ coverLetter: content.text }),
            {
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json'
                }
            }
        )
    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({
                error: error instanceof Error ? error.message : 'Unknown error'
            }),
            {
                status: 500,
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json'
                }
            }
        )
    }
})
