using System;
using System.IO;
using NUnit.Framework;
using PixelVision8.Engine.Chips;
using PixelVision8.Runner.Importers;
using PixelVision8.Runner.Parsers;

namespace PixelVision8Tests
{
    public class ColorChipTest
    {
        public static string GetTestDataFolder(string testDataFolder)
        {
            string path = AppDomain.CurrentDomain.BaseDirectory;

            return Path.Combine(path, "Content", testDataFolder);

        }

        readonly string filePath = Path.Combine(GetTestDataFolder("ProjectTemplate"), "colors.png");

        public ColorChip colorChip;
        public ColorParser colorParser;

        public bool LoadColorChip()
        {
            if (colorChip == null)
                colorChip = new ColorChip();

            if (File.Exists(filePath))
            {
                var imageBytes = File.ReadAllBytes(filePath);

                var pngReader = new PNGReader(imageBytes, colorChip.maskColor)
                    {FileName = Path.GetFileNameWithoutExtension(filePath)};

                if(colorParser == null)
                    colorParser = new ColorParser(pngReader, colorChip);
                
                colorParser.CalculateSteps();

                while (colorParser.completed == false)
                {
                    colorParser.NextStep();
                }

                return true;
            }

            return false;
        }

        [Test]
        public void TotalParsedColorsTest()
        {

            if (LoadColorChip())
            {
                
                // Assert.AreEqual(colorParser.totalColors, 16);

            }
            else
            {
                Assert.Fail("Couldn't configure Color Chip.");
            }

        }
        
        protected readonly string[] defaultColors =
        {
            "#2D1B2E",
            "#218A91",
            "#3CC2FA",
            "#9AF6FD",
            "#4A247C",
            "#574B67",
            "#937AC5",
            "#8AE25D",
            "#8E2B45",
            "#F04156",
            "#F272CE",
            "#D3C0A8",
            "#C5754A",
            "#F2A759",
            "#F7DB53",
            "#F9F4EA"
        };

        [Test]
        public void ParsedColorsTest()
        {

            if (LoadColorChip())
            {

                CollectionAssert.AreEqual(colorChip.colors,  this.defaultColors);
            }
            else
            {
                Assert.Fail("Couldn't configure Color Chip.");
            }

        }

        [Test]
        public void BGDefaultValueTest()
        {

            if (LoadColorChip())
            {
                Assert.AreEqual(colorChip.backgroundColor, 0);
            }
            else
            {
                Assert.Fail("Couldn't configure Color Chip.");
            }

        }

        [Test]
        public void BGInBoundsTest()
        {

            if (LoadColorChip())
            {

                colorChip.backgroundColor = unchecked((byte)-1);

                Assert.AreEqual(colorChip.backgroundColor, 255);
            }
            else
            {
                Assert.Fail("Couldn't configure Color Chip.");
            }

        }

        [Test]
        public void BGOutOfBoundsTest()
        {

            if (LoadColorChip())
            {

                colorChip.backgroundColor = unchecked((byte)-1);

                Assert.AreEqual(colorChip.backgroundColor, 255);
            }
            else
            {
                Assert.Fail("Couldn't configure Color Chip.");
            }

        }
    }
}
