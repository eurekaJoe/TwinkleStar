
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;

[HelpURL("www.bilibili.com/read/cv7966440")]
[SerializeField]
[PostProcess(typeof(RayMarchingRender),PostProcessEvent.AfterStack,"Custom/RayMarching")]
public class RayMarching : PostProcessEffectSettings
{
    [Tooltip("Step")] 
    public FloatParameter step = new FloatParameter() {value = 1f};

    public TextureParameter shapeTex = new TextureParameter() {value = null};
}

public sealed class RayMarchingRender : PostProcessEffectRenderer<RayMarching>
{
    private BoxCollider box;
    public override void Init()
    {
        base.Init();
        GameObject boxObj = GameObject.Find("RayMarchBox");
        if (boxObj != null) boxObj.TryGetComponent(out box);
    }

    public override void Render(PostProcessRenderContext context)
    {
        CommandBuffer cmd = context.command;
        cmd.BeginSample("RayMarch");
        PropertySheet shader = context.propertySheets.Get(Shader.Find("PostProcess/RayMarching"));
        Matrix4x4 projectionMatrx = GL.GetGPUProjectionMatrix(context.camera.projectionMatrix, false);
        shader.properties.SetMatrix("_InverseProjectorMatrix", projectionMatrx.inverse);
        shader.properties.SetMatrix("_InverseViewMatrix", context.camera.cameraToWorldMatrix);
        shader.properties.SetFloat("_Step", settings.step);
        if(settings.shapeTex.value != null) shader.properties.SetTexture("_shapeTex", settings.shapeTex);

        if (box != null)
        {
            shader.properties.SetVector("_boundMin", box.transform.position + box.center + box.size*0.5f);
            shader.properties.SetVector("_boundMax", box.transform.position + box.center - box.size*0.5f);
        }
        
        cmd.BlitFullscreenTriangle(context.source, context.destination, shader, 0);
        cmd.EndSample("RayMarch");
    }
}
