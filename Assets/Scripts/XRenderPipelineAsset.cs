using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "SRPLearn/XRendererPipelineAsset")]
public class XRenderPipelineAsset : RenderPipelineAsset
{
   protected override RenderPipeline CreatePipeline() {
       return new XRenderPipeline();
   }
}

public class XRenderPipeline: RenderPipeline {
    protected override void Render(ScriptableRenderContext context, Camera[] camears) {


        CommandBuffer cmd = new CommandBuffer();
        cmd.ClearRenderTarget(true, true, Color.black);
        context.ExecuteCommandBuffer(cmd);
        cmd.Release();



         foreach(var camera in camears) {
             RenderPerCamera(context, camera);

            if (camera.clearFlags == CameraClearFlags.Skybox && RenderSettings.skybox != null)
            {
                context.DrawSkybox(camera);
            }
        }
         context.Submit();
    }

    private ShaderTagId _shaderTag = new ShaderTagId("XForwardBase");

    private LightConfigurator _lightConfigurator = new LightConfigurator();

    private void RenderPerCamera(ScriptableRenderContext context, Camera camera) {
        context.SetupCameraProperties(camera);
        //对场景进行裁剪
        camera.TryGetCullingParameters(out var cullingParams);
        var cullingResults = context.Cull(ref cullingParams);

        _lightConfigurator.SetupShaderLightingParams(context, ref cullingResults);

        //相关参数，用来计算物体渲染时的排序
        var sortingSetting = new SortingSettings(camera);
        var drawSetting = new DrawingSettings(_shaderTag, sortingSetting);
        //相关参数，用来过滤需要渲染的物体
        var filterSetting = new FilteringSettings(RenderQueueRange.all);
        //绘制物体
        context.DrawRenderers(cullingResults, ref drawSetting, ref filterSetting);


    }
}
